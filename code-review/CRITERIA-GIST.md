# Criteria Gist

The single secret GitHub gist that stages newly discovered review criteria across every repo
and machine, before a human collates the durable ones into [REVIEW-CRITERIA.md](REVIEW-CRITERIA.md)
by hand.

- **Gist ID**: `12aa6da56817811e0f101d6c3cbf1d7f`
- **URL**: <https://gist.github.com/mholubinka1/12aa6da56817811e0f101d6c3cbf1d7f>
- **File**: `CRITERIA.md`

`address-copilot-comments` reads the gist ID from here to append newly discovered criteria
(`gh gist edit`). `code-review` Step 4 reads the gist ID from here to fetch the current
staged criteria live (`gh gist view`) alongside `REVIEW-CRITERIA.md`. Neither skill needs
any other per-machine configuration to find it.
