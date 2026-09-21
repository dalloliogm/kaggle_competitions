# Provenance

This package is a one-variable model-swap experiment derived from the public
Kaggle notebook:

- Naji, [LB 0.823 | The "Freeroll" Gemini Pro Strategy](https://www.kaggle.com/code/najiama/lb-0-823-the-freeroll-gemini-pro-strategy)

Source pulled on 2026-08-02. The downloaded kernel metadata did not expose an
explicit license (`license_name` was absent). Keep this attribution with any
private or public copy.

Relative to the exact reproduction, only the Pro-stage identity/model and its
provider-compatible sampling fields change:

- `gemini-3.1-pro-preview` becomes `claude-sonnet-5`;
- `temperature`, `top_p`, and `top_k` are omitted because Claude Sonnet 5
  rejects those sampling fields through the competition's OpenAI-compatible
  proxy; and
- temperature, output-token cap, and thinking budget remain unchanged.

Both model IDs are permitted by the competition's official `models.yaml` as of
2026-08-02. The package has not been executed locally; it is validated
statically and with the competition's official compiler.
