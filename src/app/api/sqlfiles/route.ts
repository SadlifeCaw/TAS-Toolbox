// app/api/sqlfiles/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { join, relative, normalize } from 'path';
import { existsSync, readFileSync } from 'fs';
import { basename } from 'path';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const fileParam = searchParams.get('path');

  if (!fileParam) {
    return NextResponse.json({ error: 'Missing "path" query parameter' }, { status: 400 });
  }

  const decodedPath = decodeURIComponent(fileParam);
  const ROOT_DIR = join(process.cwd(), 'Backend', 'data');
  const fullPath = normalize(join(ROOT_DIR, decodedPath));

  // Safer security check
  if (!fullPath.startsWith(ROOT_DIR)) {
    return NextResponse.json({ error: 'Access denied' }, { status: 403 });
  }

  if (!existsSync(fullPath)) {
    return NextResponse.json({ error: 'File not found' }, { status: 404 });
  }

  const content = readFileSync(fullPath, 'utf-8');
  return new NextResponse(content, {
    status: 200,
    headers: {
      'Content-Type': 'text/plain',
      'Content-Disposition': `attachment; filename="${basename(fullPath)}"`,
    },
  });
}
