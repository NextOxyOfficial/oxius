# AdsyClub — Release 8.0.49 (build 89)

পূর্ববর্তী store build: **8.0.46 (86)**। এই রিলিজে app + backend + server + web সব স্তরে বড় ফিক্স ও নতুন ফিচার।

---

## 📞 AdsyConnect Call
- Call connect না হওয়ার আসল কারণ সারানো: server-এ Agora token package missing ছিল (এখন ঠিক) + app-এর accept freshness ৩০s→৯০s, clock-skew সহনশীল।
- iOS-এ WhatsApp-স্টাইল incoming call (APNs VoIP key configure + Apple-verified)।

## 🧩 Business Network
- **পোস্ট Edit** — single-card ডিজাইন, title/description-এ @mention, hashtag যোগ/মুছা, টাইপ করার সাথে সাথে Save সক্রিয়।
- **@mention notification** চালু (Bangla push)।
- নতুন user search-এ পাওয়া যায়; like/comment/share সারির jitter বন্ধ; like-sheet/comment avatar → profile; Facebook-স্টাইল link preview।
- **MindForce: নিজের পোস্ট Edit/Delete** (list + detail view); নিরাপত্তা: শুধু মালিক edit/delete করতে পারে (backend guard)।
- Gold Sponsor manage (Delete), বড় ছবি + পুরো নাম; ডিজাইন পরিপাটি।

## 💬 AdsyConnect Chat
- চ্যাট লিস্ট লাইভ আপডেট (reload ছাড়া), চ্যাটে link-এ meta preview, header ব্যাজ ঠিক, ইনপুট gap ও status-bar fix।

## 🛒 eShop / কেনাবেচা
- Special Deals খালি দেখানো fix; product কার্ডে "BOTTOM OVERFLOWED" দাগ দূর; Sale Marketplace Load More + Recent Listings পেশাদার sizing; homepage-এ বিভিন্ন store।

## 📍 এলাকা-ভিত্তিক টার্গেটেড নোটিফিকেশন/ইমেইল (নতুন)
- "আপনার এলাকায় এখন ৪ জন ইলেকট্রিশিয়ান, ১০ জন পানির মিস্ত্রি সার্ভিস দিচ্ছেন" — push + email, real count নিয়ে; ঠিকানা না থাকলে সর্বশেষ search-করা এলাকা দিয়ে target; deep-link in-app navigate (browser নয়)।

## 🚀 পারফরম্যান্স
- Shorts প্রায় তাৎক্ষণিক খোলে; browse API থেকে N+1 query দূর (এলাকা-লিস্ট 1.85s→0.33s)।

## 🔒 Support / নিরাপত্তা
- Support ticket privacy fix (admin inbox-এ সবার ticket আর দেখা যায় না); পুরোনো ticket-এ `<p>` ট্যাগ পরিষ্কার।

## 👤 Account
- নাম সবসময় বড় হাতের অক্ষরে (পুরোনো ৭৪ জন backfill); admin/welcome/recharge ইমেইল ঠিকঠাক, ১০০% বাংলা।

## 🧹 কোড
- flutter analyze 2017 → 0 issue; ~৫,২০০ লাইন dead code মুছে; deprecated API migrate।

## 🌐 Web
- AdsyConnect web চ্যাট reply "broken code" fix; স্বাভাবিক কথ্য বাংলা।

---
ভাষা: পণ্যের সব text স্বাভাবিক কথ্য বাংলা (ইংরেজি শব্দ যেমন "সার্ভিস প্রোভাইডার" বাংলা হরফে), শুধু Pro/KYC-র মতো technical token ইংরেজি।

সংস্করণ: **8.0.49 (89)** — production aab।
