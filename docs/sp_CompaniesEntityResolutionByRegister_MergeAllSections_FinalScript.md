# Documentation: `sp_CompaniesEntityResolutionByRegister_MergeAllSections_FinalScript`

## 1) Overview

`[ADIP].[dbo].[sp_CompaniesEntityResolutionByRegister_MergeAllSections_FinalScript]` is a unified stored procedure that merges duplicate companies identified in `ADIP.dbo.DuplicateCompanies`.

It consolidates data from the company selected as **to delete** into the company selected as **to keep**, across multiple business areas:

- Comments and textual sections
- Profile/legal/register fields
- D&S sections (directorships, shareholders, related/capital)
- Contacts and addresses
- Other references (financials, names, files, capacities, orders, etc.)
- Final soft-delete and redirection in `TestCrifis2.dbo.tblAtoms`

The procedure has **no input parameters** and relies on pre-populated duplicate pairs.

---

## 2) Prerequisites

### Required source table
- `ADIP.dbo.DuplicateCompanies`

Expected minimum columns used by logic:
- `IDATOM_1`
- `IDATOM_2`
- `DateUpdated_1`
- `DateUpdated_2`
- (optional in many sections) `registernumber`, `IdRegister`

### Important expectation
Rows in `DuplicateCompanies` should represent valid duplicate pairs to be processed.

---

## 3) Keep/Delete decision rule

Across sections, the procedure repeatedly computes:

- `HasOrders_1` for `IDATOM_1`
- `HasOrders_2` for `IDATOM_2`

from `TestCrifis2.dbo.cs_orders` (with stronger priority to active-like speed/status combinations).

Then it derives:

- **idatom to keep**
- **idatom to delete**

using this rule:

1. If only one side has orders, keep that side.
2. Otherwise keep the side with the more recent `DateUpdated`.

---

## 4) Execution order inside the unified procedure

The unified procedure inlines all sections in this order:

1. **COMMENTS SECTION**
2. **PROFILE SECTION**
3. **D&S SECTION**
4. **ADDRESSES SECTION**
5. **OTHER SECTION**
6. **FINAL TBLATOMS REDIRECTION / SOFT DELETE**

---

## 5) What each section does (high level)

## 5.1 Comments section
Merges/propagates comments across:
- internal notes
- register comments
- relation comments
- employees/financials comments
- original text blocks (history, activities, brands, certification, import/export, premises, etc.)

Approach:
- append when both sides have values and they differ
- copy when keep-side is empty
- create note dictionary records when both are empty in specific flows

## 5.2 Profile section
Handles:
- legal forms (`tblCompanies2Types`) including history/current flags
- incorporation/start dates and years
- register metadata in `tblCompanyIDs`
- register status/date consistency rules
- missing company IDs
- employee and operational status records
- trading names synchronization

Includes country-specific handling for Kuwait chamber numbers (`IdOrganisation = 4024812`).

## 5.3 D&S section
Moves/merges:
- directorships (`tblCompanies2Administrators`)
- shareholders (`tblCompanies2Shareholders`)
- capital (`tblCompanies_Capital`)
- relations (`tblCompanies_Related` by `IDATOM` and `IDRELATED`)
- holdings references

## 5.4 Addresses section
Merges contact/address information:
- emails / phones / websites
- contact rows and contact links
- main/non-main address enrichment (area, street, floor, office, postal fields, etc.)
- address metadata fields
- premises re-pointing

Includes logic for same-town enrichment and different-town fallback behavior (e.g., former address type).

## 5.5 Other section
Moves or reconciles:
- company update/report dates
- listed flag
- company history
- financials and ratings/history
- activities, commerce, capacities
- files and financial files
- company names/trading names and name metadata
- `cs_orders` reassignment

---

## 6) Final `tblAtoms` soft-delete and redirection logic

After all section merges, the procedure performs final atom-level redirection in `TestCrifis2.dbo.tblAtoms`.

### 6.1 Build merge map
It builds `#MergeMap` from duplicate pairs (keep/delete derivation), then creates `#FinalMergeMap` and collapses chains:

- If `B -> C` and `C -> D`, map `B -> D`.

This ensures all updates point to a terminal kept atom.

### 6.2 Mark merged-away atoms
For each `IdatomToDelete` in final map:

- `IsDeleted = 1`
- `replacedByIdatom = final kept atom`

`EasyNumber` is normalized with this rule set:

1. If kept `EasyNumber` is `NULL` and deleted `EasyNumber` exists, copy deleted value to kept.
2. Then set deleted `EasyNumber` to kept `EasyNumber`.
3. If both have values, kept value remains authoritative for both.
4. If both are `NULL`, both remain `NULL`.

### 6.3 Cascade previously deleted atoms
If an older atom already pointed to an intermediate replacement, it is repointed to the new final kept atom.

Same cascade is applied to:
- `replacedByIdatom`
- `EasyNumber`

### 6.4 Redirect dangling `EasyNumber` pointers
If `EasyNumber` still points to an atom that is now deleted, it is redirected to the final kept target `EasyNumber` (after normalization above).

---

## 7) Idempotency and rerun behavior

The procedure contains many guards (`NOT IN`, `NOT EXISTS`, null checks), but not all operations are perfectly idempotent for every table.

Recommended practice:

- Run against a controlled batch in `DuplicateCompanies`.
- Validate effects after each run.
- Avoid running overlapping batches simultaneously.

---

## 8) Operational recommendations

1. Back up affected data (or run in a restorable environment first).
2. Load `DuplicateCompanies` with the exact target pairs.
3. Execute in a maintenance window (large cross-table updates).
4. Validate:
   - no orphan references
   - expected `replacedByIdatom` chains
   - expected `EasyNumber` redirection

---

## 9) How to execute

```sql
USE [ADIP];
GO

EXEC [dbo].[sp_CompaniesEntityResolutionByRegister_MergeAllSections_FinalScript];
GO
```

---

## 10) Key output expectations

After execution:

- merged-away atoms should be soft-deleted (`IsDeleted = 1`)
- `replacedByIdatom` should point to the final kept atom
- historical replacements should be repointed transitively
- `EasyNumber` should follow the same final replacement target logic

---

## 11) Related file

- SQL implementation:
  - `/workspace/sp_CompaniesEntityResolutionByRegister_MergeAllSections_FinalScript.sql`
