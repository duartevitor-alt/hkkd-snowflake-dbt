# Module 0: Set Up Your Snowflake Trial Account

This module walks you through creating a free 30-day Snowflake trial account. The trial includes **$400 in credits** and requires no credit card.

---

## Steps

### 1. Open the sign-up page

Go to [https://signup.snowflake.com/](https://signup.snowflake.com/)

You will see a registration form on the right-hand side of the page (see `printscreens/trial.png`).

---

### 2. Fill in your details

| Field | What to enter |
|-------|--------------|
| First name / Last name | Your name |
| Work email | Your IBM email address |
| Company | IBM |
| Why are you signing up? | Any option |

---

### 3. Choose your Snowflake configuration

On the next screen you will be asked to select an edition, cloud provider, and region. Use the following settings so that all trainees work in the same environment:

| Setting | Value |
|---------|-------|
| **Snowflake Edition** | Enterprise |
| **Cloud Provider** | AWS |
| **Region** | Europe (Paris) |

> **Why Enterprise?** The Enterprise edition includes features used in this training such as multi-cluster warehouses, column-level security, and authentication policies. The trial credits are the same regardless of edition.

> **Why AWS / Paris?** Keeping everyone on the same cloud and region avoids cross-region latency and ensures feature parity during the labs.

---

### 4. Activate your account

After submitting the form, Snowflake will send an activation email to the address you provided.

1. Open the email and click **Activate**
2. Set a password for your account
3. You will be redirected to Snowsight — the Snowflake web UI


---

## What's Next

Once your account is active, move on to **Module 1 — Configuration File** to set up `config.toml` and connect Snowflake CLI to your new account.
