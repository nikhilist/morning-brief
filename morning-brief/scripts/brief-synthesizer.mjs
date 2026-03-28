#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import process from 'process';
import OpenAI from 'openai';

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const text = fs.readFileSync(filePath, 'utf8');
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    if (!(key in process.env)) process.env[key] = value;
  }
}

const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const appDir = path.resolve(scriptDir, '..');
loadEnvFile(path.join(appDir, '.env.local'));
loadEnvFile(path.join(appDir, '.env'));

const inputPath = process.argv[2];
if (!inputPath) {
  console.error('Usage: brief-synthesizer.mjs <context.json>');
  process.exit(2);
}

const context = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
const apiKey = process.env.OPENAI_API_KEY?.trim();
if (!apiKey) {
  console.error('OPENAI_API_KEY not found');
  process.exit(3);
}

const client = new OpenAI({ apiKey });

const schema = {
  type: 'object',
  additionalProperties: false,
  required: ['executive_summary', 'pattern_to_notice', 'tomorrow_prep', 'recommended_next_move', 'things_i_can_do'],
  properties: {
    executive_summary: {
      type: 'array',
      minItems: 3,
      maxItems: 4,
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['label', 'text'],
        properties: {
          label: { type: 'string' },
          text: { type: 'string' }
        }
      }
    },
    pattern_to_notice: { type: 'string' },
    tomorrow_prep: { type: 'string' },
    recommended_next_move: { type: 'string' },
    things_i_can_do: {
      type: 'array',
      minItems: 1,
      maxItems: 3,
      items: { type: 'string' }
    }
  }
};

const prompt = `You are writing Nik's personal daily brief synthesis.

Rules:
- Be practical, concise, and specific.
- Use only the provided context. Do not invent meetings, tasks, emails, weather, or news.
- Prioritize freshness. If the context looks thin, stale, or summary-only, say so plainly and keep claims modest.
- Prefer concrete items, timestamps, and deltas over generic summarization.
- Prioritize family timing, real constraints, travel logistics, and the user's stated preference for interpretation over raw facts.
- Act like a chief of staff, not a dashboard: surface blind spots, latent risks, timing traps, and what actually matters.
- Do not merely restate obvious facts from the calendar or task list unless they change the decision-making.
- Use the `decision_support` block heavily. Prefer signal over status, blind spots over summaries, and latent risks over trivia.
- Explicitly down-rank anything listed in `decision_support.noise`.
- Make the brief smaller and sharper: 3-4 executive bullets max.
- If a trip is upcoming, treat logistics as first-class: seats, airport timing, baggage, child travel friction, hotel/car/activity gaps.
- Avoid stale-event narration. A completed event from earlier today should not appear unless it materially changes what happens next.
- "Pattern to Notice" should identify the real behavioral or operational risk in the day.
- "Tomorrow Prep" should be a short, useful setup thought for tomorrow, not a repeat of calendar text.
- "Recommended Next Move" should be a single concrete action to do next.
- "Things I Can Do" should be 1-3 explicit offers of help, phrased like actions the assistant could take or prepare next.
- If context is thin, say so plainly and keep it modest.
- Optimize for long-term usefulness, not short-term pleasantness.
- Return valid JSON only.

Context JSON:
${JSON.stringify(context, null, 2)}`;

try {
  const response = await client.responses.create({
    model: process.env.BRIEF_MODEL || 'gpt-4o-mini',
    input: [
      {
        role: 'system',
        content: [
          { type: 'input_text', text: 'You are a sharp executive briefing writer. No fluff. No hallucinations.' }
        ]
      },
      {
        role: 'user',
        content: [
          { type: 'input_text', text: prompt }
        ]
      }
    ],
    text: {
      format: {
        type: 'json_schema',
        name: 'brief_synthesis',
        schema,
        strict: true
      }
    }
  });

  const text = response.output_text?.trim();
  if (!text) throw new Error('Empty model response');
  const parsed = JSON.parse(text);
  process.stdout.write(JSON.stringify(parsed));
} catch (err) {
  console.error(err?.message || String(err));
  process.exit(4);
}
