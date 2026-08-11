# Robot Framework Suite

![Robot Framework Tests](https://github.com/jeanmatheo123/robotframework-suite/actions/workflows/ci.yml/badge.svg)

A Robot Framework suite covering both a web UI ([Sauce Demo](https://www.saucedemo.com), via SeleniumLibrary) and a REST API ([restful-booker](https://restful-booker.herokuapp.com), via RequestsLibrary). Robot Framework is often used precisely because one suite can hold both kinds of tests side by side with the same keyword-driven syntax, so this repo is built to actually show that instead of only picking one.

## What's covered

**`tests/web`** — login (standard user, the built-in `locked_out_user` account, wrong password, empty-field client-side validation) and cart behaviour (adding an item updates the badge, and the cart persists into the cart page).

**`tests/api`** — a full CRUD lifecycle against restful-booker: authenticate, create a booking, read it back, update it, delete it, and confirm the delete actually took effect with a follow-up GET. Also covers two auth edge cases that are easy to get wrong on this particular API: a failed login returns HTTP 200 with a `{"reason": "Bad credentials"}` body (not a 401), and an unauthenticated PUT is rejected with 403.

## Structure

```
tests/web/    *.robot files exercising the SeleniumLibrary keywords
tests/api/    *.robot files exercising the RequestsLibrary keywords
resources/    shared keywords — web_keywords.resource, api_keywords.resource
```

Custom keywords live in `resources/` rather than inline in the test files, so the `.robot` test files themselves read close to plain English and the actual locators/HTTP calls are defined in exactly one place.

## Running it

```bash
python -m venv .venv
.venv\Scripts\activate        # .venv/bin/activate on Linux/macOS
pip install -r requirements.txt

robot --outputdir results/web tests/web
robot --outputdir results/api tests/api
```

The web suite always runs in headless Chrome (via Selenium Manager, so no separate chromedriver setup) — there's no reason for this suite to open a visible browser window either locally or in CI.

## CI

GitHub Actions runs both suites on every push to `main`, on pull requests, and weekly. The Robot Framework HTML report/log is uploaded as a build artifact on every run.
