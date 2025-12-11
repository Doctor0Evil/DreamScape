# HSM-Backed Encryption Design for Subject Identity Vault

This design describes how to protect `subject_identity_vault` with hardware-backed keys in clinical deployments, aligning with best practices for medical data security.

## Key Management Model

- All encryption keys for `subject_identity_vault` are generated and stored in a Hardware Security Module (HSM), e.g., PCIe or network-attached HSM.
- Application services obtain data encryption keys (DEKs) via a key management protocol (e.g., KMIP) under strict policy:
  - Keys are scoped to the DreamScape identity-vault use-case.
  - Keys cannot be exported in plaintext from the HSM.
- Data stored in Postgres:
  - `dob_full_enc` and `contact_enc` are encrypted blobs using DEKs whose key material never leaves the HSM.
  - If an attacker exfiltrates the database, encrypted values remain unintelligible without HSM-held keys.

## Application Flow

1. Application authenticates to HSM using a service identity and policy-configured credentials.
2. For write:
   - Generate a per-record or per-tenant DEK inside the HSM or retrieve an existing DEK.
   - Encrypt identifiers; store ciphertext in `subject_identity_vault`.
3. For read:
   - Enforce access control at the app-level, log reidentification in `reidentification_log`, then request decryption from HSM.
4. All key rotation and destruction is managed centrally in the HSM; schema remains stable.

## Separation of Duties

- Database administrators cannot decrypt identity data without HSM access.
- Application operators cannot read raw data from the DB without going through audited APIs.
- HSM administrators do not have access to application-layer pseudonymized clinical data.

## Tactical implementation notes

- Use envelope encryption: DEK wrapped by an HSM-managed Key Encryption Key (KEK). DEKs stored only in ciphertext form in the DB or a secure secrets store with the KEK safely retained by the HSM.
- Use a per-tenant or per-record DEK strategy to allow fine-grained revocation and rotation.
- Use HSM-provided audit logs to correlate every key usage with the application-level `reidentification_log`.
- Log the `actor_id`, `purpose`, and `legal_basis` when requesting decryption, and record the HSM request ID to support cross-system audits.

## Regarding reidentification and clinical governance

- Reidentification must have a documented legal basis (consent or statutory), an approved purpose, and must be logged in `reidentification_log` before performing the actual decryption.
- Implement a time-limited, tokenized flow for decrypted data consumption by the consuming application to reduce exposure time for identifiers.

## Regulatory considerations

- Use a key lifecycle policy consistent with regulatory expectations for medical data.
- Ensure the HSM is configured and audited, and controls are integrated into the QMS (ISO 13485) security records.

