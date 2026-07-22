import { defineCollection, z } from 'astro:content';

const workSchema = z.object({
  image: z.string(),
  title: z.string(),
  releaseYear: z.number(),
  genre: z.string(),
  editingApproach: z.string(),
  type: z.enum(['영화', '드라마']),
  synopsis: z.string(),
  releaseDate: z.string().optional(),
  airPeriod: z.object({ start: z.string(), end: z.string() }).optional(),
  director: z.string(),
  writer: z.string(),
  cast: z.array(z.string()),
  watchLink: z.object({ label: z.string(), url: z.string() }),
  sortOrder: z.number(),
});

const works = defineCollection({
  loader: async () => {
    const supabaseUrl = import.meta.env.SUPABASE_URL;
    const supabaseAnonKey = import.meta.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseAnonKey) {
      const seed = await import('./content/works/works.json');
      return seed.default;
    }

    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(supabaseUrl, supabaseAnonKey);
    const { data, error } = await supabase.from('works').select('*').order('sort_order', { ascending: true });
    if (error) throw new Error(`Supabase works fetch failed: ${error.message}`);

    return data.map((row) => ({
      id: row.id,
      image: row.image,
      title: row.title,
      releaseYear: row.release_year,
      genre: row.genre,
      editingApproach: row.editing_approach,
      type: row.type,
      synopsis: row.synopsis,
      releaseDate: row.release_date ?? undefined,
      airPeriod: row.air_start && row.air_end ? { start: row.air_start, end: row.air_end } : undefined,
      director: row.director,
      writer: row.writer,
      cast: row.cast_members,
      watchLink: { label: row.watch_label, url: row.watch_url },
      sortOrder: row.sort_order,
    }));
  },
  schema: workSchema,
});

export const collections = { works };
