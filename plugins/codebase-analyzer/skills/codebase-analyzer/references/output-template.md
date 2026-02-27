# Output Document Template

Use the following structure for the output markdown file. Every section must be substantive — do not include sections where you have no findings. Write in technical prose, not bullet-point lists, unless a list genuinely improves clarity (e.g., dependency catalogs).

```markdown
# Comprehensive Technical Analysis: {Project Name}

> Generated: {date} | Analyzed directory: `{path}`

## Executive Summary
<!-- 3-5 paragraph high-level overview: what this codebase is, key architectural decisions,
     overall health assessment, and top 3 recommendations. -->

## 1. Project Overview
### 1.1 Purpose & Scope
### 1.2 Repository Structure
### 1.3 Technology Stack
<!-- Languages, frameworks, major dependencies with versions. -->

## 2. Architecture
### 2.1 High-Level Architecture
<!-- Describe the overall pattern (monolith, microservices, etc.)
     and how major components relate. Use ASCII diagrams if helpful. -->
### 2.2 Component Breakdown
<!-- Each major module/package/service gets a subsection with:
     - Responsibility
     - Key interfaces/exports
     - Internal structure -->
### 2.3 Data Architecture
<!-- Database(s), schemas, migrations, caching, data flow. -->
### 2.4 API Surface
<!-- Endpoints, protocols, auth, versioning. -->

## 3. Application Flows
<!-- Walk through up to 5 critical user journeys or system flows end-to-end.
     Show the path through the code with file references.
     For each flow, include: trigger/entry point, step-by-step path through modules, and final outcome.
     After documenting the primary flows, include a subsection:
     ### 3.X Additional Flows Reference
     List any remaining notable flows not covered in detail, with a brief description
     and the key entry-point files where a reader can begin tracing each one independently. -->

## 4. Design Decisions & Trade-offs
<!-- Document notable architectural and design decisions.
     For each, explain: what was chosen, likely rationale, and trade-offs. -->

## 5. Code Quality & Patterns
### 5.1 Code Organization & Conventions
### 5.2 Type Safety & Validation
### 5.3 Error Handling
### 5.4 Dependency Management

## 6. Testing
### 6.1 Testing Strategy & Coverage
### 6.2 Test Patterns & Quality
### 6.3 Testing Gaps

## 7. DevOps & Deployment
### 7.1 Build System
### 7.2 CI/CD Pipeline
### 7.3 Deployment Architecture
### 7.4 Observability & Monitoring

## 8. Security Considerations
<!-- Auth, secrets, input validation, known vulnerability patterns. -->

## 9. Assessment

### 9.1 Strengths
<!-- What this codebase does well. Be specific with file/pattern references. -->

### 9.2 Areas for Improvement
<!-- Concrete, actionable improvements. Prioritize by impact. -->

### 9.3 Risks & Technical Debt
<!-- Known risks, accumulated debt, fragile areas. -->

### 9.4 Recommendations
<!-- Prioritized list of recommended actions with estimated effort
     (low/medium/high) and impact (low/medium/high). -->

## Appendix
### A. File Tree (Top 3 Levels)
### B. Dependency Catalog
### C. Key File Reference
<!-- Quick-reference table: purpose → file path for the most important files. -->
```
