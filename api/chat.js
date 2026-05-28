// Vercel サーバーレス関数 — Claude API へのプロキシ
// 環境変数 ANTHROPIC_API_KEY は Vercel のダッシュボードで設定する

// システムプロンプト — 玉置彩奈のアシスタントとして振る舞う
const SYSTEM_PROMPT = `あなたは玉置 彩奈（Ayana Tamaki）のポートフォリオサイトの AI アシスタントです。
訪問者からの質問に、日本語で親しみやすく・簡潔に答えてください。
長い説明が必要な場合でも、300文字以内を目安にまとめてください。

【プロフィール】
- 名前: 玉置 彩奈（読み: たまき あやな / Ayana Tamaki）
- 職種: AI エンジニア / ML リサーチャー
- 専門: LLM プロダクト開発、RAG、Fine-tuning、MLOps 基盤設計

【スキル】
Python, PyTorch, LangChain, RAG, Fine-tuning, FastAPI, Docker, AWS, GCP, Kubernetes, MLflow, React

【主な実績】
1. 社内チャットボット構築（RAG / LangChain / Azure）— 問い合わせ工数 40% 削減
2. 画像異常検知システム（ResNet / GradCAM）— 検出精度 98.5%
3. 需要予測モデル（LSTM / Transformer / Prophet）— MAPE 8.2%
4. 音声感情分析 API（Whisper + Fine-tuning / Kubernetes）

【営業時間・連絡先】
- 営業時間: 9:00〜19:00
- 電話番号: 090-1234-5678
- メールアドレス: ayana.t@gmail.com

【よくある質問と回答】
Q: どんな仕事・作業が得意ですか？
A: チャットボットの開発が得意です。

ポートフォリオサイト以外の話題（政治・有害なコンテンツ等）は丁重にお断りし、
「彩奈のスキルや実績についてお気軽にどうぞ！」と案内してください。`;

module.exports = async function handler(req, res) {
  // CORS ヘッダー
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // プリフライトリクエスト対応
  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'POST メソッドのみ対応しています' });
    return;
  }

  // APIキーを環境変数から取得
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: 'ANTHROPIC_API_KEY が設定されていません' });
    return;
  }

  const { messages } = req.body;
  if (!messages || !Array.isArray(messages)) {
    res.status(400).json({ error: 'messages フィールドが必要です' });
    return;
  }

  try {
    // Claude API を呼び出す
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5',
        max_tokens: 1024,
        system: SYSTEM_PROMPT,
        messages: messages,
      }),
    });

    const data = await response.json();

    if (response.ok) {
      const text = data?.content?.[0]?.text || '（返答を取得できませんでした）';
      res.status(200).json({ content: text });
    } else {
      const errMsg = data?.error?.message || `API エラー (HTTP ${response.status})`;
      res.status(response.status).json({ error: errMsg });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
