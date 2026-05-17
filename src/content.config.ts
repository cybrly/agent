import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const cheatsheets = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/cheatsheets' }),
  schema: z.object({
    title: z.string(),
    category: z.enum([
      'recon',
      'enumeration',
      'web',
      'active-directory',
      'privesc-linux',
      'privesc-windows',
      'pivoting',
      'reverse-shells',
    ]),
    description: z.string().optional(),
    tags: z.array(z.string()).default([]),
    os: z.array(z.enum(['linux', 'windows', 'macos', 'any'])).default(['any']),
    ports: z.array(z.number()).default([]),
    order: z.number().default(100),
  }),
});

export const collections = { cheatsheets };
