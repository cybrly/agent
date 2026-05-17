import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

export const GET: APIRoute = async () => {
  const sheets = await getCollection('cheatsheets');
  const docs = sheets.map((s) => ({
    slug: s.id.split('/').pop()!,
    title: s.data.title,
    description: s.data.description ?? '',
    category: s.data.category,
    tags: s.data.tags,
    ports: s.data.ports,
    os: s.data.os,
    body: stripMarkdown(s.body ?? ''),
  }));
  return new Response(JSON.stringify(docs), {
    headers: { 'Content-Type': 'application/json' },
  });
};

function stripMarkdown(md: string): string {
  return md
    .replace(/```[\s\S]*?```/g, (m) => m.replace(/```\w*\n?|\n?```/g, ''))
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/[#>*_~]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 4000);
}
