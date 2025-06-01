import { NextRequest, NextResponse } from "next/server";
import path from "path";
import fs from "fs";
import os from "os";
import archiver from "archiver";

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
    const normalizedPath = configPath.replace(/\\/g, "/");
    const sourceFolder = path.resolve(ROOT_DIR, normalizedPath);

    const relativePath = path.relative(ROOT_DIR, sourceFolder);
    if (relativePath.startsWith("..") || path.isAbsolute(relativePath)) {
      return NextResponse.json({ error: "Access denied" }, { status: 403 });
    }

    if (!fs.existsSync(sourceFolder)) {
      return NextResponse.json({ error: "Source folder not found" }, { status: 404 });
    }

    const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "ps-script-"));
    fs.cpSync(sourceFolder, tempDir, { recursive: true });

    const configFilePath = path.join(tempDir, "Configs.ps1");
    let configContent = fs.readFileSync(configFilePath, "utf-8");

    // Update the variables in the config content
    for (const [key, val] of Object.entries(values)) {
      const regex = new RegExp(`^\\s*\\${key}\\s*=\\s*(['"]).*?\\1.*$`, "m");

      if (regex.test(configContent)) {
        console.log(`Replacing variable: ${key} with value: ${val}`);
        configContent = configContent.replace(regex, `${key} = "${val}"`);
      } else {
        console.log(`Variable ${key} not found in config. Appending.`);
        configContent += `\n${key} = "${val}"`;
      }
    }

    fs.writeFileSync(configFilePath, configContent, "utf-8");

    const sanitizedZipName = script.replace(/[\s]/g, "_"); // Replace only spaces
    const zipNameEncoded = encodeURIComponent(`${sanitizedZipName}.zip`);

    const archive = archiver("zip", { zlib: { level: 9 } });
    archive.directory(tempDir, false);
    archive.finalize();

    const stream = archive as unknown as ReadableStream;

    archive.on("end", () => {
      fs.rmSync(tempDir, { recursive: true, force: true });
    });

    return new NextResponse(stream, {
      status: 200,
      headers: {
        "Content-Type": "application/zip",
        // UTF-8 filename support with fallback
        "Content-Disposition": `attachment; filename*=UTF-8''${zipNameEncoded}`,
      },
    });
  } catch (error) {
    console.error("Error in /api/powershellfiles:", error);
    return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
  }
}
