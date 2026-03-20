# Documentation: `sp_tblDuplicateCompanies_SoftDeleteAndRedirectAtoms`

## 1) Purpose

`[ADIP].[dbo].[sp_tblDuplicateCompanies_SoftDeleteAndRedirectAtoms]` performs controlled soft-delete and redirection in `TestCrifis2.dbo.tblAtoms` using a pre-defined merge map.

It is intended for scenarios where merge decisions are already known in advance.

Input mapping table:

- `ADIP.dbo.tblDuplicateCompanies`
  - `idatomtodelete`
  - `mergedidatom`

---

## 2) What the procedure updates

For impacted rows in `TestCrifis2.dbo.tblAtoms`, it updates:

- `IsDeleted`
- `replacedByIdatom`
- `EasyNumber`

---

## 3) Core behavior

### 3.1 Validate prerequisites

The procedure checks:

- `dbo.tblDuplicateCompanies` exists
- required columns exist (`idatomtodelete`, `mergedidatom`)
- `TestCrifis2.dbo.tblAtoms` exists

If any check fails, it raises an error and exits.

### 3.2 Build clean merge map

From `tblDuplicateCompanies`, it:

- converts values to `INT` (`TRY_CONVERT`)
- removes invalid rows (null/zero/self-mapping)
- deduplicates by `idatomtodelete`

### 3.3 Collapse map chains to final target

If map has chains, they are flattened:

- `A -> B`
- `B -> C`
- result becomes `A -> C`

This ensures each delete atom points to a final kept atom.

### 3.4 EasyNumber normalization before delete updates

Rule applied per keep/delete pair:

1. If kept `EasyNumber` is `NULL` and deleted has value, copy deleted value to kept.
2. Deleted then follows kept `EasyNumber`.
3. If both have values, kept remains authoritative.
4. If both are `NULL`, both remain `NULL`.

### 3.5 Direct delete redirection

For each `idatomtodelete` in final map:

- set `IsDeleted = 1`
- set `replacedByIdatom = mergedidatom`
- set deleted `EasyNumber = kept EasyNumber`

### 3.6 Historical cascade redirection

If a row was previously redirected to an atom that is now deleted, it is re-pointed to the final kept atom:

- previous `replacedByIdatom` is updated transitively
- `EasyNumber` is aligned to final kept
- `IsDeleted` is enforced to `1`

### 3.7 EasyNumber dangling pointer fix

If any row still has `EasyNumber` pointing to a deleted atom ID, that value is redirected to the final kept atom’s `EasyNumber`.

---

## 4) Transaction and safety model

- `XACT_ABORT ON`
- full `TRY/CATCH`
- single explicit transaction (`BEGIN TRANSACTION` / `COMMIT`)
- rollback on any failure

This guarantees all-or-nothing behavior.

---

## 5) Returned output

At completion, procedure returns a summary row:

- `MergePairs`
- `DirectDeletedRows`
- `CascadeRedirectRows`
- `EasyNumberRedirectRows`

---

## 6) How to execute

```sql
USE [ADIP];
GO

EXEC [dbo].[sp_tblDuplicateCompanies_SoftDeleteAndRedirectAtoms];
GO
```

---

## 7) Required input table shape

If you need to create the input table:

```sql
USE [ADIP];
GO

IF OBJECT_ID(N'dbo.tblDuplicateCompanies', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.tblDuplicateCompanies
    (
        idatomtodelete INT NOT NULL,
        mergedidatom   INT NOT NULL
    );
END;
GO
```

> Note: If you are using a different table name (for example `tblDuplicateCompaniesA`), either:
> - copy rows into `dbo.tblDuplicateCompanies`, or
> - adjust the procedure source to read from your chosen table.

---

## 8) Example mapping and result

Input:

- `1001 -> 2001`
- `2001 -> 3001`

Procedure resolves final mapping:

- `1001 -> 3001`
- `2001 -> 3001`

Expected effects:

- `1001`, `2001`: `IsDeleted = 1`, `replacedByIdatom = 3001`
- `EasyNumber` aligned using kept (`3001`) rules
- any old rows pointing to `1001`/`2001` are redirected transitively

---

## 9) Validation queries (post-run)

Check that mapped deletes are flagged:

```sql
SELECT t.IDATOM, t.IsDeleted, t.replacedByIdatom, t.EasyNumber
FROM TestCrifis2.dbo.tblAtoms t
JOIN ADIP.dbo.tblDuplicateCompanies d
  ON d.idatomtodelete = t.IDATOM;
```

Check for unresolved replacement chains:

```sql
SELECT a.IDATOM, a.replacedByIdatom, b.IsDeleted AS TargetIsDeleted
FROM TestCrifis2.dbo.tblAtoms a
LEFT JOIN TestCrifis2.dbo.tblAtoms b
  ON b.IDATOM = a.replacedByIdatom
WHERE a.replacedByIdatom IS NOT NULL
  AND ISNULL(b.IsDeleted, 0) = 1;
```

---

## 10) File reference

- SQL implementation:
  - `/workspace/sp_tblDuplicateCompanies_SoftDeleteAndRedirectAtoms.sql`
