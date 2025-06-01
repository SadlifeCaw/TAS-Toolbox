import { NextRequest, NextResponse } from "next/server";
import path from "path";
import fs from "fs/promises";

const filePath = path.join(process.cwd(), "Backend", "data", "downloadHistory.json");

type DownloadRecord = {
  user: string;
  script: string;
  action: "copy" | "download";
  timestamp: string;
  status: "Success" | "Failed";
};

export async function POST(request: NextRequest) {
  const record: DownloadRecord = await request.json();

  if (
    !record.user ||
    !record.script ||
    !record.action ||
    !record.timestamp ||
    !record.status
  ) {
    return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
  }

  try {
    let data = "[]";
    try {
      data = await fs.readFile(filePath, "utf-8");
    } catch {
      // If file doesn't exist, create new
    }

    const records: DownloadRecord[] = JSON.parse(data);
    records.push(record);

    await fs.writeFile(filePath, JSON.stringify(records, null, 2), "utf-8");

    return NextResponse.json({ message: "Download history saved" }, { status: 201 });
  } catch (error) {
    console.error("Error writing file:", error);
    return NextResponse.json({ error: "Failed to save download history" }, { status: 500 });
  }
}

export async function GET() {
  try {
    const data = await fs.readFile(filePath, "utf-8");
    const records: DownloadRecord[] = JSON.parse(data);
    return NextResponse.json(records);
  } catch {
    return NextResponse.json([]);
  }
}
