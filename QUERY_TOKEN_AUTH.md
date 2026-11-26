# Query Token Authentication untuk OpenMausBot

Fitur ini menambahkan autentikasi lewat query parameter `?token=xxx` untuk akses API, mirip dengan GptPI.

## Setup

### 1. Generate Token

```bash
openssl rand -base64 32
```

### 2. Set Environment Variable

```bash
export OMB_QUERY_TOKEN="your_generated_token_here"
```

Atau tambahkan di `.env`:

```env
OMB_QUERY_TOKEN=your_generated_token_here
```

### 3. Start Server

```bash
pnpm dev:server
# atau
OMB_QUERY_TOKEN=xxx node dist-server/index.js
```

## Usage

### Dengan Token (✅ Berhasil)

```bash
# Health check
curl "http://localhost:8799/api/health?token=YOUR_TOKEN"

# List bots
curl "http://localhost:8799/api/bots?token=YOUR_TOKEN"

# Get bot detail
curl "http://localhost:8799/api/bots/BOT_ID?token=YOUR_TOKEN"

# Send message
curl -X POST "http://localhost:8799/api/bots/BOT_ID/messages?token=YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from API"}'
```

### Tanpa Token (❌ Gagal)

```bash
curl "http://localhost:8799/api/bots"
# Returns: 401 Unauthorized atau 403 Forbidden
```

## Security

- Token memberi **full admin/loopback access** (scope: `["admin", "client"]`)
- Token di-compare dengan `timingSafeEqual` (constant-time comparison)
- Hanya valid lewat query param `?token=xxx`, **tidak** lewat header
- Token sebaiknya **minimal 32 karakter random**
- Jangan commit token ke git

## Contoh Use Case

### 1. ChatGPT Plugin / Custom GPT

```
https://your-domain.com/api/bots?token=xxx
```

### 2. External Integration

```javascript
const BASE_URL = 'https://openmausbot.yourdomain.com';
const TOKEN = process.env.OMB_QUERY_TOKEN;

async function listBots() {
  const res = await fetch(`${BASE_URL}/api/bots?token=${TOKEN}`);
  return res.json();
}
```

### 3. Webhook Callback

```bash
# Cloudflare Tunnel dengan query token
https://your-tunnel.trycloudflare.com/api/webhooks/WEBHOOK_ID?token=xxx
```

## Implementation Details

### Files Changed

1. **`server/request-auth.ts`**
   - Tambah `staticQueryToken` di `ResolveOptions`
   - Check query token sebelum session auth
   - Return loopback scope dengan admin access

2. **`server/index.ts`**
   - Load `OMB_QUERY_TOKEN` dari env
   - Pass ke semua `resolveRequestAuth()` calls

3. **`.env.example`**
   - Dokumentasi env var

### Auth Flow

```
1. Request masuk dengan ?token=xxx
   ↓
2. Extract query param "token"
   ↓
3. Compare dengan OMB_QUERY_TOKEN (timingSafeEqual)
   ↓
4. Jika match → Grant loopback access (admin scope)
   ↓
5. Jika tidak match → Lanjut ke bearer/cookie/loopback check biasa
```

### Comparison dengan Metode Auth Lain

| Method | Header/Query | Scope | Use Case |
|--------|--------------|-------|----------|
| Bearer Token | `Authorization: Bearer omb_sess_xxx` | Session-based | Paired devices |
| Cookie | `Cookie: omb_session_xxx` | Session-based | Browser |
| Query Token | `?token=xxx` | **Admin/Loopback** | External APIs, plugins |
| Loopback | `Host: localhost` | Admin/Service | Local processes |

## Testing

```bash
# Generate token dan lihat test commands
./test-query-token.sh
```

## Deployment

### Docker Compose

```yaml
services:
  openmausbot:
    environment:
      - OMB_QUERY_TOKEN=${OMB_QUERY_TOKEN}
    # atau hardcode (not recommended)
    # - OMB_QUERY_TOKEN=your_token_here
```

### Cloudflare Tunnel

```bash
# Start tunnel dengan env var
OMB_QUERY_TOKEN=xxx cloudflared tunnel run my-tunnel

# Access dari external
curl "https://my-tunnel.example.com/api/bots?token=xxx"
```

## Troubleshooting

### "unauthorized" atau "forbidden"

- Pastikan `OMB_QUERY_TOKEN` di-set di env
- Token harus **exact match** (case-sensitive)
- Token minimal harus ada (tidak boleh empty string)

### Token tidak bekerja di production

- Check env var loaded: `echo $OMB_QUERY_TOKEN`
- Restart server setelah set env var
- Cek logs server untuk error

### CORS issues

Query token bypass CORS check karena pakai loopback scope. Jika masih ada CORS error, check origin headers atau proxy config.

## Comparison dengan GptPI

| Feature | GptPI | OpenMausBot (ini) |
|---------|-------|-------------------|
| Query param | `?token=xxx` ✅ | `?token=xxx` ✅ |
| Bearer header | `Bearer xxx` ✅ | `Bearer omb_sess_xxx` (session only) |
| Scope | Fleet-wide | Admin/Loopback |
| Multi-token | ✅ (per agent) | ❌ (single static) |
| Session creation | ❌ | ❌ (direct loopback) |

Future enhancement bisa tambah **per-bot token** atau **API key management** kayak GptPI Fleet.
