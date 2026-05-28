require 'webrick'
require 'net/http'
require 'json'
require 'uri'

# ── .env ファイルの自動読み込み ────────────────────────────────────────
# 外部 gem 不要のシンプルな実装。
# 環境変数が既に設定されている場合は上書きしない（export が優先される）。
env_path = File.join(__dir__, '.env')
if File.exist?(env_path)
  File.foreach(env_path) do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')  # 空行・コメントをスキップ
    key, value = line.split('=', 2)
    next unless key && value
    ENV[key] ||= value  # 既に設定済みの環境変数は上書きしない
  end
  puts "📄 .env を読み込みました"
end

# ── チャットAPIサーブレット ──────────────────────────────────────────────
class ChatServlet < WEBrick::HTTPServlet::AbstractServlet

  # CORS プリフライトリクエスト対応
  def do_OPTIONS(request, response)
    set_cors_headers(response)
    response.status = 204
  end

  # POST /api/chat — フロントエンドからのメッセージを受け取り Claude に問い合わせる
  def do_POST(request, response)
    set_cors_headers(response)
    response['Content-Type'] = 'application/json; charset=utf-8'

    # APIキーを環境変数から取得（HTMLには絶対に書かない）
    api_key = ENV['ANTHROPIC_API_KEY']
    unless api_key
      response.status = 500
      response.body = JSON.generate({ error: 'ANTHROPIC_API_KEY が設定されていません。起動前に export ANTHROPIC_API_KEY=... を実行してください。' })
      return
    end

    # リクエストボディをパース
    body = JSON.parse(request.body)
    messages = body['messages'] || []

    # Claude API を呼び出して返答を取得
def call_claude(api_key, messages)
  uri  = URI('https://api.anthropic.com/v1/messages')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl       = true
  http.read_timeout  = 60

  req = Net::HTTP::Post.new(uri)
  req['Content-Type']      = 'application/json'
  req['x-api-key']         = api_key
  req['anthropic-version'] = '2023-06-01'
  req.body = JSON.generate({
    model:      'claude-haiku-4-5,
    max_tokens: 1024,
    system:     system_prompt,
    messages:   messages
  })

  res = http.request(req)

  "HTTP #{res.code}\n\nHeaders:\n#{res.to_hash.inspect}\n\nBody:\n#{res.body[0..500]}"
end

  private

  # CORS ヘッダーをセット
  def set_cors_headers(response)
    response['Access-Control-Allow-Origin']  = '*'
    response['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type'
  end

  # Claude API (claude-haiku-4-5) を呼び出す
  def call_claude(api_key, messages)
    uri  = URI('https://api.anthropic.com/v1/messages')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl    = true
    http.read_timeout = 60

    req = Net::HTTP::Post.new(uri)
    req['Content-Type']      = 'application/json'
    req['x-api-key']         = api_key
    req['anthropic-version'] = '2023-06-01'
    req.body = JSON.generate({
      model:      'claude-haiku-4-5',
      max_tokens: 1024,
      system:     system_prompt,
      messages:   messages
    })

    res  = http.request(req)
　　"HTTP #{res.code}\n\nHeaders:\n#{res.to_hash.inspect}\n\nBody:\n#{res.body[0..500]}"
　end

  # システムプロンプト — 玉置彩奈のアシスタントとして振る舞う
  def system_prompt
    <<~PROMPT
      あなたは玉置 彩奈（Ayana Tamaki）のポートフォリオサイトの AI アシスタントです。
      訪問者からの質問に、日本語で親しみやすく・簡潔に答えてください。
      長い説明が必要な場合でも、300文字以内を目安にまとめてください。

      【プロフィール】
      - 名前: 玉置 彩奈（Ayana Tamaki）
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
      「彩奈のスキルや実績についてお気軽にどうぞ！」と案内してください。
    PROMPT
  end
end

# ── Web サーバー設定 ──────────────────────────────────────────────────
server = WEBrick::HTTPServer.new(
  Port:        3000,
  DocumentRoot: '/Users/tamaki/Desktop/myHP',
  MaxClients:  10,
  Logger:       WEBrick::Log.new($stdout, WEBrick::Log::INFO),
  AccessLog:   [[
    $stdout,
    WEBrick::AccessLog::COMBINED_LOG_FORMAT
  ]]
)

# /api/chat エンドポイントをマウント
server.mount('/api/chat', ChatServlet)

trap('INT')  { server.shutdown }
trap('TERM') { server.shutdown }

puts "🚀 サーバー起動: http://localhost:3000"
puts "💬 チャット API:  http://localhost:3000/api/chat"
puts "⌨️  停止するには Ctrl+C"

server.start
