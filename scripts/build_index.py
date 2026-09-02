#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""홈페이지 검색 인덱스(site/index.json)의 소제목·줄수를 다시 만든다.
   groups / title / desc / group / gi 는 기존 값을 그대로 둔다."""
import json, re, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IDX  = os.path.join(ROOT, "site", "index.json")

def clean(h):
    h = re.sub(r'[`*_]', '', h)
    h = h.replace('(', '').replace(')', '')
    h = re.sub(r'\s+', ' ', h).strip()
    return h

d = json.load(open(IDX, encoding="utf-8"))
tot_h = tot_l = 0
for doc in d["docs"]:
    p = os.path.join(ROOT, "references", doc["slug"] + ".md")
    if not os.path.exists(p):
        print("  ⚠ 없음:", p); continue
    s = open(p, encoding="utf-8").read()
    doc["lines"] = len(s.splitlines())
    # 🛑 코드 펜스 안의 `## 주석` 은 소제목이 아니다. GDScript 문서화 주석이 ## 로 시작한다
    heads, fence = [], False
    for ln in s.split("\n"):
        if ln.startswith("```"):
            fence = not fence
            continue
        if fence:
            continue
        m = re.match(r'^#{2,6} (.+)$', ln)
        if m:
            heads.append(clean(m.group(1)))
    doc["heads"] = heads
    tot_h += len(doc["heads"]); tot_l += doc["lines"]

json.dump(d, open(IDX, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
print(f"문서 {len(d['docs'])}편 · {tot_l:,}줄 · 소제목 {tot_h:,}개")
