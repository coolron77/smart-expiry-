# Smart Expiry

Product expiry and inventory management for small shopkeepers. It tracks every batch with its own expiry date, warns before stock expires, sells first-expiring stock first, and shows exactly how much money is lost to expiry. It also tells the shopkeeper what to do about it.

It runs in two modes:

| Mode | When | Data lives in |
|---|---|---|
| **Offline demo** (default) | `js/config.js` is empty | This browser (localStorage). Good for trying it out and for presentations with no internet. |
| **Online** | Supabase URL + anon key in `js/config.js` | Supabase (Postgres) with Row Level Security, on any device. Also enables email and WhatsApp alerts. |

---

## 1. Run it (2 minutes)

1. Double-click **`start.bat`**. It starts a small local server and opens http://localhost:5500.
   *No Python?* Install it from python.org and tick "Add python.exe to PATH". Or open the folder in VS Code and use the **Live Server** extension.
   On Mac/Linux, run `python3 serve.py`.
2. Click **Create an account**.
3. On the dashboard, click **Load demo data**. This adds 29 products, 5 suppliers and six months of sales and wastage history, all dated relative to today, so every screen has meaningful content.

> The app must be opened through a server (`http://localhost…`), not by double-clicking `index.html`. Browsers block modern JavaScript modules on `file://` pages.

---

## 2. Features

**Dashboard.** Urgent banner for expired and expiring-today stock, a 30-day "what expires when" strip (tap a day), and 8 key numbers: products, expired, expiring within 7 days, safe, low stock, stock value, expired stock on the shelf, and expiry loss this year. It also shows a needs-action list, suggestions, five charts (expiry status, monthly wastage value, monthly expired batches, stock by category, weekly stock movement), recently added stock and recently expired stock.

**Products.** Add, edit and delete products. Each has a name, brand, barcode, category, unit, purchase and selling price, low-stock level, supplier, photo and notes. You can search by name, brand or barcode, filter by category or status, and sort. The global search in the top bar also finds suppliers.

**Batches.** Every delivery is its own batch, with batch/lot number, quantity, purchase price, supplier, and manufacturing, expiry and received dates. One product can have many batches with different expiry dates.

**Expiry tracking.** Each batch is automatically grouped as Expired, Today, 1–3 days, 4–7 days, 8–15 days, 16–30 days or Safe. Colours: red = expired, orange = expiring soon (within 7 days), yellow = needs attention (8–30 days), green = safe. Statuses recalculate whenever the date changes, even with the page left open. Date maths uses whole calendar days, so time zones and daylight saving never cause off-by-one errors.

**Stock.**
- Stock in and sales. Sales take from the first-expiring batch automatically and **never sell expired stock**.
- Adjustments for count corrections, damage and returns to supplier.
- "Remove from stock" for expired items.
- Full stock history with filters and CSV export, plus a "needs restocking" list.
- Negative stock is blocked unless you turn it on in Settings.

**Waste and loss calculator.** Shows loss for this month, last month, 3 months, this year or 12 months. Includes month-over-month change, expired stock still on the shelf, waste rate (loss ÷ purchases), a 12-month chart, the products with the highest wastage (with waste rate), and loss by category and by supplier. A **Sell these first** list ranks stock by money at risk, using each product's real sales speed.

**Smart suggestions.** Rule-based and calculated from your own data. Examples:
- "Remove 17 expired items"
- "Milk expires in 1 day. Consider a 40% discount: about 7 won't sell in time at your current pace"
- "You have 18 packets of Parle-G expiring next week"
- "Paneer often expires before it is sold. Try ordering around 12 instead of 14"
- "Wastage increased this month"
- "Restock Tata Salt: lasts about 2 days at current sales"

**Alerts.** Expiry reminders at the periods you choose (default 30, 15, 7, 3, 1 days and on the day), expired alerts and low-stock alerts. Every alert has a unique key, so **the same alert is never created twice**. Other alert features:
- Unread badge and alert history.
- Optional pop-up notifications on the device.
- "Share on WhatsApp" and "Email summary" buttons, which work without any setup.
- Automatic daily email and WhatsApp alerts in online mode (see section 4).

**Barcode scanner.**
- Phone or laptop camera scanning: the browser's built-in BarcodeDetector, or the ZXing library as a fallback.
- Scan from a photo.
- USB and Bluetooth scanners, which type into the box.
- If a product is found: Sell 1, Sell more, or Add stock.
- If not found: looks the barcode up in the free Open Food Facts database to pre-fill the name. You can then add it as a new product or attach the barcode to an existing one.

**Reports.** Inventory, Expiry, Financial loss, Stock movements and Sales reports. Periods: daily, weekly, monthly, last month, 3 months, year or custom dates. Export to **PDF and CSV** (opens in Excel), print, or save a snapshot to reopen later. The PDF writer is built in, so exports work offline.

**Suppliers.** Contact details (call, WhatsApp and email buttons), purchase history, products supplied, and a list of **expired stock from each supplier** to use when asking for credit. Each supplier also shows its expiry loss and waste rate.

**Settings.** Shop profile, reminder periods (including custom ones), default low-stock level, alert channels, negative stock rule, light/dark/system theme, demo data, JSON backup, delete all data, and change password.

**Design.** Responsive for desktop, tablet and phone. Phones get a bottom navigation bar with a central Scan button. Includes light and dark modes, keyboard focus styles and reduced-motion support.

---

## 3. Go online with Supabase

1. Create a free project at <https://supabase.com>.
2. **SQL Editor → New query**: paste all of `supabase/schema.sql` and click **Run**. This creates:
   - 8 tables: shops, suppliers, products, product_batches, sales, stock_movements, notifications, reports.
   - Row Level Security on every table, plus a trigger that stops rows linking to another shop's data.
   - Stock functions that validate input and update batch quantities and history in one transaction.
   - Alert generation with de-duplication.
   - A `product-images` storage bucket where each shop can only write to its own folder.
3. **Project Settings → API**: copy the **Project URL** and the **anon public** key into `js/config.js`.
   - The anon key is meant to be public. RLS is what protects the data.
   - **Never** put the `service_role` key in the website.
4. **Authentication → URL Configuration**:
   - Set **Site URL** to where the site runs (e.g. `http://localhost:5500` or your deployed URL).
   - Add the same URL under **Redirect URLs**. Password-reset and confirmation links return there.
5. Reload the app and create an account. By default Supabase asks new users to confirm their email first. You can turn this off for a demo under Authentication → Providers → Email.

**Optional check:** paste `supabase/tests/rls_and_stock_test.sql` into the SQL editor and run it. It creates two test shops inside a transaction and checks the following, then rolls everything back:
- RLS isolation and the cross-shop write guard
- first-expiry-first selling and the expired-sale block
- negative-stock prevention
- wastage recording and alert de-duplication

---

## 4. Daily email and WhatsApp alerts (online mode)

These run on the server in the Supabase Edge Function `supabase/functions/send-alerts`, so no secret key is ever in the browser.

**Credentials you need**

| For | Service | Secrets to set |
|---|---|---|
| Email | [Resend](https://resend.com) (free tier) | `RESEND_API_KEY`, `ALERT_FROM_EMAIL` (e.g. `Smart Expiry <alerts@yourdomain.com>`, domain verified in Resend) |
| WhatsApp | [Twilio](https://twilio.com) WhatsApp | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM` (e.g. `whatsapp:+14155238886`) |
| Schedule | — | `CRON_SECRET`: any long random string |

Notes:
- Without a verified domain, Resend only delivers to your own Resend account email. That's enough for a demo.
- For a demo, use the **Twilio WhatsApp Sandbox**: each recipient first sends the sandbox "join" code to the sandbox number. Sending to any customer number needs an approved WhatsApp Business sender and message templates.

**Deploy** (requires the [Supabase CLI](https://supabase.com/docs/guides/cli)):

```bash
supabase login
supabase link --project-ref YOUR-PROJECT-REF
supabase functions deploy send-alerts --no-verify-jwt
supabase secrets set CRON_SECRET=... RESEND_API_KEY=... ALERT_FROM_EMAIL="Smart Expiry <alerts@yourdomain.com>"
supabase secrets set TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

**Schedule:** enable the `pg_cron` and `pg_net` extensions (Database → Extensions). Then edit and run `supabase/cron.sql`, which sends alerts every day at 8:00 AM India time.

**Test:** in the app, go to **Settings → Send a test alert**. The result for each channel appears as a message. Each alert is sent once per channel, because it is marked `email_sent_at` / `whatsapp_sent_at`.

---

## 5. Camera scanning on a phone

Phone browsers only allow the camera on **https** sites (or `localhost` on the same device). To scan with your phone, deploy the folder to a free static host:
- **Netlify**: drag and drop the folder at app.netlify.com/drop.
- **Vercel** or **GitHub Pages** also work.

Then add that https URL to Supabase's Site URL and Redirect URLs. USB/Bluetooth scanners work everywhere without this.

---

## 6. Tests (Playwright)

```bash
pip install -r tests/requirements.txt
python -m playwright install chromium
python -m pytest
```

There are 60 tests. They cover:
- Registration, login, logout, validation and forgot password.
- Per-shop data isolation, and passwords stored hashed.
- Add, edit, search, filter and delete products, plus photo upload.
- Multiple batches per product.
- Expiry bucket boundaries, month/leap-year/DST maths and reminder stages.
- First-expiry-first selling and overselling.
- Negative-stock settings, adjustments, and wastage recording.
- Alert creation, alert de-duplication and reminder settings.
- Scanner flows: found, unknown and attach barcode.
- Every page loading without JavaScript errors.
- CSV/PDF exports, supplier CRUD, theme, and phone/tablet layouts with no sideways scrolling.

Tests run in offline mode with external network blocked, so they don't need a Supabase project. Set `HEADED=1` to watch them run.

---

## 7. Project structure

```
index.html              App shell (single page, hash routes)
css/app.css             Design tokens (light/dark) and all components
js/config.js            Supabase URL + anon key (empty = offline demo mode)
js/app.js               Start-up, login gate, layout, router, global search
js/state.js             Shared state and refresh
js/components.js        Shared UI + stock dialogs (stock in, sale, adjust, remove)
js/lib/                 expiry engine, charts, PDF/CSV export, scanner, formatting, DOM helpers
js/logic/               analytics (KPIs, wastage, sell-first), recommendations, alert rules
js/data/                store interface: local-store (offline), supabase-store (online),
                        stock-ops (stock rules), demo-data (simulated history)
js/views/               one file per page
supabase/schema.sql     database, RLS, stock + alert functions, storage
supabase/functions/     send-alerts edge function (email + WhatsApp)
supabase/cron.sql       daily schedule
tests/                  Playwright tests
serve.py, start.bat     local server
```

## 8. Good to know

- **Offline demo mode** is for trying the app and presenting it. Each browser keeps its own data, and clearing browser data deletes it. Passwords are salted and hashed (PBKDF2) even here. Use online mode for real shops.
- The same stock and alert rules exist twice: in JavaScript for offline mode (`js/data/stock-ops.js`, `js/logic/alerts.js`) and in SQL for online mode (`schema.sql`). If you change a rule, change both.
- Losses are valued at **purchase price**. "Expiry loss" counts written-off expired stock plus expired stock still on the shelf.
