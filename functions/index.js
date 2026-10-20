const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getAppCheck } = require('firebase-admin/app-check');
const { defineSecret } = require('firebase-functions/params');
const { onRequest } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');

initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');

const coachInstructions = `You are GymGen AI, a knowledgeable, supportive fitness and wellness coach.
Answer the user's question directly and clearly. You may answer general questions,
but prioritize exercise, strength training, cardio, mobility, sports performance,
recovery, sleep, nutrition, healthy habits, fitness motivation, and progress.
Give practical steps, explain important trade-offs, and ask a brief follow-up when
key details such as experience, equipment, schedule, or goal are missing. Do not
pretend to know personal details the user has not shared. Keep answers easy to scan.

Safety: You are not a doctor, dietitian, or emergency service. Do not diagnose,
prescribe treatment, or guarantee results. For chest pain, fainting, severe
shortness of breath, or a serious injury, tell the user to stop exercising and
seek urgent medical care. For persistent pain, medical conditions, pregnancy,
medication questions, or eating-disorder concerns, recommend a qualified health
professional. Do not recommend crash diets, extreme weight loss, dangerous
supplements, or performance-enhancing drugs. Give general, balanced guidance,
and note when advice needs personalization. Be respectful and non-judgmental.`;

function sendError(res, status, message) {
  res.status(status).json({ error: { message } });
}

exports.geminiCoach = onRequest(
  {
    region: 'asia-south1',
    cors: true,
    secrets: [geminiApiKey],
    timeoutSeconds: 120,
    maxInstances: 5,
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.set('Allow', 'POST');
      return sendError(res, 405, 'Use POST to send a chat message.');
    }

    const authorization = req.get('Authorization') || '';
    const match = authorization.match(/^Bearer\s+(.+)$/i);

    if (!match) {
      return sendError(res, 401, 'Please sign in to use the coach.');
    }

    try {
      await getAuth().verifyIdToken(match[1]);
    } catch (error) {
      logger.info('Coach request rejected: invalid Firebase Auth token.');
      return sendError(
        res,
        401,
        'Your sign-in has expired. Please sign in again.',
      );
    }

    // Firebase Authentication is always required. If an App Check token is
    // provided, verify it as an additional abuse-prevention measure.
    const appCheckToken = req.get('X-Firebase-AppCheck');

    if (appCheckToken) {
      try {
        await getAppCheck().verifyToken(appCheckToken);
      } catch (error) {
        logger.info('Coach request rejected: invalid Firebase App Check token.');
        return sendError(res, 403, 'This app could not pass App Check.');
      }
    }

    const message = typeof req.body?.message === 'string'
      ? req.body.message.trim()
      : '';

    if (!message || message.length > 4000) {
      return sendError(res, 400, 'Enter a message of 1 to 4000 characters.');
    }

    const rawHistory = Array.isArray(req.body?.history)
      ? req.body.history
      : [];

    if (rawHistory.length > 20) {
      return sendError(res, 400, 'Chat history is too long. Start a new chat.');
    }

    const history = [];

    for (const turn of rawHistory) {
      if (
        !turn ||
        !['user', 'assistant', 'model'].includes(turn.role) ||
        typeof turn.text !== 'string' ||
        turn.text.length > 4000
      ) {
        return sendError(res, 400, 'The chat history contains invalid data.');
      }

      history.push({
        role: turn.role === 'model' ? 'assistant' : turn.role,
        content: turn.text,
      });
    }

    try {
      const geminiResponse = await fetch(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': geminiApiKey.value(),
          },
          body: JSON.stringify({
            systemInstruction: {
              parts: [{ text: coachInstructions }],
            },
            contents: [
              ...history.map((turn) => ({
                role: turn.role === 'assistant' ? 'model' : turn.role,
                parts: [{ text: turn.content }],
              })),
              {
                role: 'user',
                parts: [{ text: message }],
              },
            ],
            generationConfig: {
              maxOutputTokens: 900,
            },
          }),
          signal: AbortSignal.timeout(90000),
        },
      );

      const data = await geminiResponse.json().catch(() => ({}));

      if (!geminiResponse.ok) {
        const providerMessage =
          data.error?.message || 'No provider error detail';

        logger.error('Gemini API request failed.', {
          status: geminiResponse.status,
          error: providerMessage,
        });

        if (geminiResponse.status === 429 || geminiResponse.status === 503) {
          return sendError(
            res,
            503,
            'Gemini is busy or the free-tier request limit was reached. Please try again shortly.',
          );
        }

        if (
          geminiResponse.status === 401 ||
          geminiResponse.status === 403
        ) {
          return sendError(
            res,
            502,
            'Gemini API key or API access is not configured correctly.',
          );
        }

        return sendError(res, 502, 'Gemini could not complete the request.');
      }

      const text = (data.candidates?.[0]?.content?.parts || [])
        .map((part) => typeof part.text === 'string' ? part.text : '')
        .join('')
        .trim();

      if (!text) {
        logger.warn('Gemini API returned no text.', {
          finishReason: data.candidates?.[0]?.finishReason || 'unknown',
          blockReason: data.promptFeedback?.blockReason || 'none',
        });

        return sendError(
          res,
          502,
          'Gemini returned an empty or blocked response.',
        );
      }

      return res.status(200).json({ text });
    } catch (error) {
      logger.error('Gemini coach request failed.', error);
      return sendError(
        res,
        503,
        'The AI service is temporarily unavailable. Please retry.',
      );
    }
  },
);