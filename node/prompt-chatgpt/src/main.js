import OpenAI from 'openai';
import { getStaticFile, throwIfMissing } from './utils.js';

export default async ({ req, res }) => {
  // Ensure the required environment variables are set
  throwIfMissing(process.env, ['OPENAI_API_KEY', 'OPENAI_MODEL']);

  if (req.method === 'GET') {
    return res.text(getStaticFile('index.html'), 200, {
      'Content-Type': 'text/html; charset=utf-8',
    });
  }

  try {
    // Ensure the request body contains the required 'prompt'
    throwIfMissing(req.body, ['prompt']);
  } catch (err) {
    return res.json({ ok: false, error: err.message }, 400);
  }

  const openai = new OpenAI();

  try {
    // Use the model specified in the environment variable
    const response = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL, // Use the model from env
      max_tokens: parseInt(process.env.OPENAI_MAX_TOKENS ?? '512'),
      messages: [{ role: 'user', content: req.bodyJson.prompt }],
    });

    const completion = response.choices[0].message.content;
    return res.json({ ok: true, completion }, 200);
  } catch (err) {
    return res.json({ ok: false, error: 'Failed to query model.' }, 500);
  }
};
