- created: 2026-07-13
- created_by: opus-4.8
- created_during: f/bootstrap-kauk

## Blockers

None to start the GitHub-Pages path. The AWS path is ready to run once the host is chosen.

## Questions

- **Host for kauk.ai: GitHub Pages (zero-cost MVP) or AWS S3+CloudFront+Route53+ACM?**
  Recommendation: Pages now to unblock; move to AWS when `apt.kauk.org` heavy artifacts or
  WORM/retention needs arrive (Panopticon already runs on AWS, so the account + patterns
  exist). Both serve the same `site/` tree; the projection is host-agnostic.

## Findings

`site/` is a self-contained static projection (CNAME=kauk.ai, .nojekyll, index.html, an
example `packages/<pkg>/`). Serving is host-agnostic; only the deploy differs.

## Proposal

**GitHub Pages:** push `site/` as the `kaukai` org Pages repo, custom domain `kauk.ai`
(see kaukai-org).

**AWS (operator uses OpenTofu normally — these are the raw aws-cli equivalents to adapt):**

    # bucket for the site (name must match the DNS name for website hosting convention)
    aws s3api create-bucket --bucket kauk.ai --region eu-west-1 \
      --create-bucket-configuration LocationConstraint=eu-west-1
    aws s3 website s3://kauk.ai/ --index-document index.html --error-document index.html
    aws s3 sync ./site s3://kauk.ai/ --delete

    # TLS cert MUST be in us-east-1 for CloudFront
    aws acm request-certificate --region us-east-1 --domain-name kauk.ai \
      --subject-alternative-names '*.kauk.ai' --validation-method DNS
    # -> add the returned CNAME validation record in Route 53, then create the distribution
    #    (origin = the S3 website endpoint, viewer-protocol redirect-to-https, default root
    #    object index.html), and a Route 53 A/AAAA ALIAS for kauk.ai -> the distribution.

Prefer the OpenTofu module form for anything durable; the above is the imperative sketch.
`apt.kauk.org` later = a second bucket/prefix behind the same distribution.

## Testing

`curl -I https://kauk.ai` → 200 + valid TLS; `kauk.ai/<pkg>/` resolves the projected page.
