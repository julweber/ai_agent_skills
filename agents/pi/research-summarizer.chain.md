---
name: research-summarizer
description: Chains web-researcher and summarizer to research a topic and produce a concise summary of the most important findings for solving a problem.
scope: project
---

## web-researcher
output: research-context.md

Research {task} and gather comprehensive information from web sources. Focus on finding documentation, tutorials, best practices, and real-world examples that address the specific scenario or problem.

## summarizer
reads: research-context.md

Analyze the research findings from {previous} and create a concise summary of the most important results. Extract key insights, actionable recommendations, and relevant references that directly help solve the problem at hand. Organize by priority and highlight the most critical information first.
