// app/api/sqlfiles/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { join, relative } from 'path';
import { existsSync, readFileSync } from 'fs';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const fileParam = searchParams.get('path');

  if (!fileParam) {
    return NextResponse.json({ error: 'Missing "path" query parameter' }, { status: 400 });
  }

  const decodedPath = decodeURIComponent(fileParam);

  const ROOT_DIR = join(process.cwd(), 'Backend', 'data');
  const normalizedPath = decodedPath.replace(/\//g, '\\');
  const fullPath = join(ROOT_DIR, normalizedPath);

  const relativePath = relative(ROOT_DIR, fullPath);
  if (relativePath.startsWith('..') || relativePath.startsWith('/') || relativePath.startsWith('\\')) {
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
    },
  });
}
