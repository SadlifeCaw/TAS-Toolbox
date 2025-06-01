import { NextRequest, NextResponse } from "next/server";
import path from "path";
import fs from "fs";
import os from "os";
import { promisify } from "util";
import { exec } from "child_process";
import archiver from "archiver";
import { PassThrough } from "stream";

const execAsync = promisify(exec);

export async function POST(req: NextRequest) {
  try {
    const { configPath, values, script } = await req.json();

    if (!configPath || !values || !script) {
      return NextResponse.json(
        { error: 'Missing "configPath", "values" or "script" in body' },
        { status: 400 }
      );
    }

    const ROOT_DIR = path.join(process.cwd(), "Backend", "data", "PS Scripts");

    // Normalize configPath slashes
    const normalizedPath = configPath.replace(/\\/g, "/");
    const sourceFolder = path.resolve(ROOT_DIR, normalizedPath);

    // Path traversal protection: sourceFolder must be inside ROOT_DIR
    const relativePath = path.relative(ROOT_DIR, sourceFolder);
    if (
      relativePath.startsWith("..") ||
      path.isAbsolute(relativePath)
    ) {
      return NextResponse.json({ error: "Access denied" }, { status: 403 });
    }

    // Check source folder exists
    if (!fs.existsSync(sourceFolder)) {
      return NextResponse.json({ error: "Source folder not found" }, { status: 404 });
    }

    // Create a temp working folder
    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "ps-script-"));

    // Copy source folder contents to tempDir
    fs.cpSync(sourceFolder, tempDir, { recursive: true });

    // Path to the Config.ps1 inside tempDir
    const configFilePath = path.join(tempDir, "Config.ps1");

    // Generate new Config.ps1 content from values object
    const lines = Object.entries(values).map(
      ([key, val]) => `${key} = "${val}"`
    );
    const newConfigContent = lines.join("\n");

    // Overwrite Config.ps1 with new content
    fs.writeFileSync(configFilePath, newConfigContent, "utf-8");

    // Prepare zip file name
    const zipName = `${script.replace(/\s+/g, "_")}.zip`;

    // Create archiver and pipe to PassThrough
    const archive = archiver("zip", { zlib: { level: 9 } });
    const passthrough = new PassThrough();
    archive.pipe(passthrough);

    const chunks: Buffer[] = [];
    passthrough.on("data", (chunk: Buffer) => {
      chunks.push(chunk);
    });

    // Add tempDir contents to archive and finalize
    archive.directory(tempDir, false);
    await archive.finalize();

    // Wait for the stream to finish
    await new Promise<void>((resolve, reject) => {
      passthrough.on("end", resolve);
      passthrough.on("error", reject);
    });

    // Remove temp directory
    fs.rmSync(tempDir, { recursive: true, force: true });

    const buffer = Buffer.concat(chunks);

    return new NextResponse(buffer, {
      status: 200,
      headers: {
        "Content-Type": "application/zip",
        "Content-Disposition": `attachment; filename="${zipName}"`,
      },
    });
  } catch (error) {
    console.error("Error in /api/powershellfiles:", error);
    return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
  }
}
