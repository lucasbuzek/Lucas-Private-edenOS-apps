---
title: "Collection of WebMCP tools"
source_url: "https://github.com/GoogleChromeLabs/webmcp-tools/blob/main/README.md"
original_archive: "/EDEN-lucas-family/AI MCP tool/#webMCP/webmcp-tools:webmcp-tools at main · GoogleChromeLabs:webmcp-tools · GitHub.webarchive"
retrieved_at: "2026-10-29"
upstream_repository: "GoogleChromeLabs/webmcp-tools"
upstream_branch: main
upstream_blob_sha: "a216607ff4f035972684334fc9b5a08af1ef3bc9"
source_license: "Apache-2.0 (repository license; observe any per-file notices)"
status: "SOURCE_LATEST_MAIN | OFFLINE_HTML_CANDIDATE | NOT_DROBOX_REPLACED"
content_origin: "upstream GitHub repository file, not decoded Safari archive"
---

# Agentic description

Original GoogleChromeLabs webmcp-tools repository landing documentation: developer tools, evaluator CLI, page tools polyfill, official sample sites and links to related implementations.

**Canonical source:** https://github.com/GoogleChromeLabs/webmcp-tools/blob/main/README.md

**Archive represented:** `/EDEN-lucas-family/AI MCP tool/#webMCP/webmcp-tools:webmcp-tools at main · GoogleChromeLabs:webmcp-tools · GitHub.webarchive`

**Content acquisition:** Exact current `main` repository Markdown text read through authenticated GitHub connector; not a live rendered GitHub site snapshot and not an archived Safari payload. Source links point outside the offline copy and may require internet to open.

**Page sections:** Collection of WebMCP tools; Developer Utilities; Demos; Disclaimer.

**Capabilities:** Read, search and cite the embedded source text offline. Interactive GitHub menus, accounts, embedded demos, remote dependencies and upstream links are deliberately not reproduced or falsely reported as functional.

**License:** Apache-2.0 repository; attribution and original copyright notices preserved where present. See https://github.com/GoogleChromeLabs/webmcp-tools/blob/main/LICENSE .

# Full recovered upstream source text

# Collection of WebMCP tools

This repository contains a suite of developer utilities and demos designed to support the adoption of the WebMCP API.

## Developer Utilities

- [**WebMCP - Model Context Tool Inspector**](https://github.com/beaufortfrancois/model-context-tool-inspector): A Chrome Extension to let web developers inspect web pages to verify if WebMCP tools are correctly exposed, visualize the input schema, and debug connection issues directly within the browser.
- [**WebMCP Evals**](webmcp-evals/): A CLI Tool to evaluate the tool-calling capabilities of LLMs by defining test cases and schemas to verify if an interactive agent correctly calls tools based on user inputs.
- [**WebMCP Skills**](webmcp-skills/): A collection of agent skills and testing workflows for designing, role-playing, evaluating, auditing, and implementing WebMCP tools into web applications.
- [**WebMCP Polyfill**](demos/shared/webmcp-polyfill.js): A JavaScript polyfill to make WebMCP tools and CSS pseudo-classes work in browsers that do not support the API natively.

## Demos

- [**A mini-site explainer of WebMCP**](demos/explainer/):
  A side-by-side demo of how AI agents interact with a web page before WebMCP (site scraping)
  and a future where the page declares structured tools with **WebMCP**.
- [**Travel WebMCP Demo (Imperative)**](demos/react-flightsearch/): A React-based flight search application designed to demonstrate WebMCP integration. This project showcases how a web application can expose structured tools to an AI agent or automation layer, allowing it to programmatically interact with the UI (searching flights, applying filters, reading results) via a standardized interface.
- [**Le Petit Bistro (Declarative)**](demos/french-bistro/): A WebMCP simple implementation for a restaurant reservation system. It allows an AI agent to interact directly with a web-based booking form, validating and submitting data on behalf of the user using declarative tool definitions.
- [**WebMCP zaMaker! (Imperative)**](demos/pizza-maker/): A demo where AI agents can control size, style, toppings, and layers to build the perfect pizza using imperative tools.
- [**Mystery Doors (Declarative & Imperative)**](demos/doors/): A simple multi-page demo showcasing WebMCP capabilities using both declarative and imperative approaches.
- [**WebMCP Maze (Imperative)**](demos/webmcp-maze/): A maze escape game where the player navigates entirely by prompting an AI agent in the browser — no keyboard or mouse input.
- [**CineFlow (Imperative)**](demos/ticket-booking/): A movie ticket purchase flow where AI agents can update location, query movies by genre, and select showtimes to start a checkout process.
- [**Order Tracking (Declarative)**](demos/order-tracking/): A simulated e-commerce order tracking and returns system allowing an AI agent to query order history and initiate product returns using declarative tools.
- [**L'Atelier Hotel Chain (Imperative & Declarative)**](demos/hotel-chain/): A high-fidelity hotel booking application designed to showcase the power of WebMCP. This demo illustrates how AI agents can interact with a modern web application through both imperative and declarative tools.
- [**WebMCP Sports (Imperative & Declarative)**](demos/sport-shop-angular/): A modern e-commerce storefront for high-performance sports equipment, built with Angular and Vanilla CSS.
- [**The Morning Ritual (Imperative)**](demos/coffee-shop/): A premium coffee boutique demo showcasing agentic reordering, technical spec analysis, and catalog navigation.
- [**UrbanEstates (Imperative)**](demos/real-estate-map/): A real-estate map application that demonstrates imperative tool registration, allowing an AI agent to interact with property filters and map views.
- [**Luxe Leather (Declarative)**](demos/leather-bag/): A premium e-commerce site for hand-crafted leather bags built with Angular and WebMCP. This demo showcases how an AI agent can interact with a web application to search products, check policies, and manage a shopping cart using declarative tools.
- [**WebMCP Smart Home (Imperative)**](demos/smart-home/): A sleek, interactive dashboard where an AI agent can dynamically reconfigure home control components (e.g., front door cameras, thermostats, smart lights, energy distribution) based on user intents.
- [**WebMCP Page Agent (Imperative)**](demos/page-agent/): A Gemini-powered meta-demo that lets you control any WebMCP-enabled website using simple natural language commands.
- [**Pixel Art Studio (Imperative)**](demos/pixel-art-studio/): A pixel-art drawing board where people and AI agents share the same tools. Agents compose whole scenes in SVG that the studio turns into crisp, palette-matched pixel art, and can manage palettes and layers or replace a selected area with new art.
- [**Spreadsheet (Imperative)**](demos/spreadsheet/): A full spreadsheet where people and AI agents share 27 tools. Agents type values and formulas like a person, format cells, sort, add conditional formats and charts, and manage sheets, and every change is one undo step that lights up on the sheet.

Check out our curated list of WebMCP demos in the [Awesome WebMCP List](AWESOME_WEBMCP.md).

## Disclaimer

This is not an officially supported Google product. This project is not
eligible for the [Google Open Source Software Vulnerability Rewards
Program](https://bughunters.google.com/open-source-security).

