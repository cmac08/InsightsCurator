# UI Table Display Configuration

## Fixed Column Layout

The data table now shows these columns for **every query**, providing consistent and comprehensive insight information:

| Column | Field | Type | Width | Special Formatting |
|--------|-------|------|-------|-------------------|
| **Insight Name** | Name | Text | 150px | Auto-number |
| **Account** | Account__c | Text | 150px | Lookup reference |
| **Solution** | EDGE_Product_Name__c | Text | 150px | Product name |
| **Status** | Status__c | Text | 120px | 🎨 Color-coded |
| **Likelihood** | Likelihood__c | Text | 120px | 🎨 Color-coded |
| **Rank** | Rank__c | Number | 80px | 1 decimal place |
| **Est. Revenue** | Estimated_Annual_Revenue__c | Text | 130px | Formula field |
| **Actions** | - | Actions | 60px | View/Edit |

## Color Coding

### Status Field Colors
- 🟢 **Open** - Green (`slds-text-color_success`)
- ⚪ **Closed** - Gray (`slds-text-color_weak`)
- ⚫ **Deferred** - Default
- ⚪ **Archived** - Gray (`slds-text-color_weak`)

### Likelihood Field Colors
- 🟢 **Very High** - Bold Green (`slds-text-color_success` + bold)
- 🟢 **High** - Green (`slds-text-color_success`)
- ⚫ **Medium** - Default
- ⚪ **Low** - Gray (`slds-text-color_weak`)

## Backend Field Guarantee

The system **always queries these essential fields**, regardless of what the AI returns:

```apex
Essential Fields (Always Included):
- Id
- Name
- Account__c
- EDGE_Product_Name__c
- Status__c
- Likelihood__c
- Rank__c
- Estimated_Annual_Revenue__c
```

If the AI requests additional fields (like `Insight_Details__c`), they're added to this base set.

## Benefits

✅ **Consistent Display** - Users always see the same columns
✅ **Complete Information** - All important fields visible at once
✅ **Visual Clarity** - Color coding helps prioritize at a glance
✅ **No Missing Data** - Backend ensures all fields are present
✅ **Better UX** - No confusing column changes between queries

## Example Table Display

```
┌─────────────────┬──────────────┬─────────────┬─────────┬────────────┬──────┬──────────────┬────┐
│ Insight Name    │ Account      │ Solution    │ Status  │ Likelihood │ Rank │ Est. Revenue │ ⚙  │
├─────────────────┼──────────────┼─────────────┼─────────┼────────────┼──────┼──────────────┼────┤
│ INS-00001      │ Acme Corp    │ EDGE Core   │ Open    │ Very High  │ 1.0  │ $50,000      │ ⚙  │
│ INS-00002      │ Global Inc   │ Product X   │ Open    │ High       │ 2.5  │ $75,000      │ ⚙  │
│ INS-00003      │ Tech LLC     │ Solution Y  │ Deferred│ Medium     │ 5.0  │ $25,000      │ ⚙  │
│ INS-00004      │ Finance Co   │ EDGE Plus   │ Closed  │ Low        │ 8.0  │ $10,000      │ ⚙  │
└─────────────────┴──────────────┴─────────────┴─────────┴────────────┴──────┴──────────────┴────┘
```

## Row Actions

Click the ⚙ icon on any row to:
- **View** - Open record in new tab (view mode)
- **Edit** - Open record in new tab (edit mode)

## Implementation Details

### Frontend (LWC)
- Fixed column definition (no dynamic generation)
- `enrichResults()` method adds CSS classes for color coding
- Consistent user experience across all queries

### Backend (Apex)
- `InsightFieldSchema.getDefaultFields()` defines essential fields
- `InsightQueryService.normalizeFields()` ensures they're always included
- OpenAI prompt instructs AI to include these fields

### Query Flow
```
User Query
    ↓
OpenAI generates JSON with essential + requested fields
    ↓
Backend ensures essential fields are present
    ↓
Frontend displays in fixed column layout with color coding
    ↓
User sees consistent, complete information
```