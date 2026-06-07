# Cloudflare R2 Media Storage Setup

This project supports Cloudflare R2 for Django media uploads through
`django-storages` and the R2 S3-compatible API. Static files continue to use
WhiteNoise; only user/admin uploaded media moves to R2.

## 1. Cloudflare Dashboard

1. Go to Cloudflare Dashboard > R2 > Create bucket.
2. Create a bucket, for example `adsyclub-media`.
3. Open the bucket > Settings > Public access.
4. Connect a custom domain, for example `media.adsyclub.com`.
5. Disable the `r2.dev` public development URL after the custom domain works.
6. Go to R2 > Manage R2 API Tokens.
7. Create an API token with Object Read & Write access scoped to the media bucket.
8. Copy the Access Key ID and Secret Access Key once, then store them only in server environment variables.

## 2. Server Environment

Add these variables to the production environment, not to git:

```env
CLOUDFLARE_R2_MEDIA_ENABLED=true
CLOUDFLARE_R2_ACCOUNT_ID=your_cloudflare_account_id
CLOUDFLARE_R2_BUCKET_NAME=adsyclub-media
CLOUDFLARE_R2_ACCESS_KEY_ID=your_r2_access_key_id
CLOUDFLARE_R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
CLOUDFLARE_R2_CUSTOM_DOMAIN=media.adsyclub.com
CLOUDFLARE_R2_PUBLIC_URL=https://media.adsyclub.com
```

Optional:

```env
CLOUDFLARE_R2_ENDPOINT_URL=https://<ACCOUNT_ID>.r2.cloudflarestorage.com
CLOUDFLARE_R2_REGION=auto
CLOUDFLARE_R2_CACHE_CONTROL=public, max-age=31536000, immutable
CLOUDFLARE_R2_QUERYSTRING_AUTH=false
```

## 3. Install Dependencies

```bash
source ~/adsyclub/venv/bin/activate
pip install -r requirements.txt
```

## 4. Smoke Test Before Migration

```bash
cd ~/adsyclub
source venv/bin/activate
python manage.py shell -c "from django.core.files.storage import default_storage; from django.core.files.base import ContentFile; p=default_storage.save('r2-smoke-test.txt', ContentFile(b'ok')); print(default_storage.url(p))"
```

The printed URL should start with `https://media.adsyclub.com/`.

## 5. Copy Existing Media

Use `rclone`, `aws s3 sync`, or another S3-compatible tool. Do not delete local
media until the app has been verified in production.

Example with AWS CLI:

```bash
aws s3 sync ~/adsyclub/media/ s3://adsyclub-media/ \
  --endpoint-url https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

## 6. Deploy

1. Pull latest code.
2. Install requirements.
3. Add env variables.
4. Restart only the Django app service.
5. Upload a test image from admin/app.
6. Confirm the response URL and browser-loaded image use the R2 custom domain.

