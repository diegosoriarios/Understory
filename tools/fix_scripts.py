#!/usr/bin/env python3
"""One-shot Godot 3 -> Godot 4 GDScript fixes for this project.

Transformations:
1. `set_velocity(x) / set_up_direction(D) / move_and_slide() / x = velocity`
   -> `velocity = x / up_direction = D / move_and_slide() / x = velocity`
   (final assignment dropped when x == velocity).
2. Removes member `var velocity = ...` declarations that shadow the native
   CharacterBody2D.velocity property (a compile error in Godot 4).
3. `f(Callable(A, B).bind(self)[, speed])` -> `f(A, B, self[, speed])`.
4. `timer.connect("timeout", Callable(self, "m"))` -> `timer.timeout.connect(m)`.
5. Bare `yield()` -> `await get_tree().process_frame`.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

FILES = [
    "EnemyH.gd",
    "Scripts/Bullet.gd",
    "Scripts/BulletEnemy.gd",
    "Scripts/BulletEnemy2.gd",
    "Scripts/BulletEnemy3.gd",
    "Scripts/Player.gd",
    "Scripts/Walker.gd",
    "Scripts/Enemies/Boss1.gd",
    "Scripts/Enemies/Boss2.gd",
    "Scripts/Enemies/Boss3.gd",
    "Scripts/Enemies/Enemy1.gd",
    "Scripts/Enemies/Enemy2.gd",
    "Scripts/Enemies/Enemy3.gd",
    "Scripts/Enemies/Enemy4.gd",
    "Scripts/Enemies/Enemy5.gd",
    "Scripts/Enemies/Enemy7.gd",
    "Scripts/Enemies/Enemy9.gd",
    "Scripts/Enemies/Enemy11.gd",
    "Scripts/Enemies/Enemy12.gd",
]


def fix_velocity_block(lines):
    """set_velocity(x) / set_up_direction(D) / move_and_slide() / x = velocity"""
    out = []
    i = 0
    n_blocks = 0
    while i < len(lines):
        m = re.match(r"^(\s*)set_velocity\((\w+)\)\s*$", lines[i])
        if (
            m
            and i + 2 < len(lines)
            and re.match(r"^\s*set_up_direction\(.+\)\s*$", lines[i + 1])
            and re.match(r"^\s*move_and_slide\(\)\s*$", lines[i + 2])
            and re.match(r"^\s*(\w+) = velocity\s*$", lines[i + 3])
        ):
            ind, var = m.group(1), m.group(2)
            dir_expr = re.match(r"^\s*set_up_direction\((.+)\)\s*$", lines[i + 1]).group(1)
            out.append(f"{ind}velocity = {var}\n")
            out.append(f"{ind}up_direction = {dir_expr}\n")
            out.append(f"{ind}move_and_slide()\n")
            tail = lines[i + 3].rstrip("\n").strip()
            if tail != "velocity = velocity":
                out.append(lines[i + 3].rstrip("\n") + "\n")
            n_blocks += 1
            i += 4
        elif (
            m
            and i + 2 < len(lines)
            and re.match(r"^\s*move_and_slide\(\)\s*$", lines[i + 1])
            and re.match(r"^\s*\w+ = velocity\s*$", lines[i + 2])
        ):
            ind = m.group(1)
            out.append(f"{ind}move_and_slide()\n")
            n_blocks += 1
            i += 3
        else:
            out.append(lines[i])
            i += 1
    return out, n_blocks


def fix_shadow_velocity(text):
    n = 0
    out = []
    for line in text.splitlines(keepends=True):
        if re.match(r"^var velocity = (Vector2\(\)|Vector2\.ZERO)\s*$", line):
            n += 1
            continue
        out.append(line)
    return "".join(out), n


def fix_callable_calls(text):
    text, n1 = re.subn(
        r"Callable\((.+?), (.+?)\)\.bind\(self\)(, ?\d+)?",
        r"\1, \2, self\3",
        text,
    )
    text, n2 = re.subn(
        r'timer\.connect\("timeout", Callable\(self, "(\w+)"\)\)',
        r"timer.timeout.connect(\1)",
        text,
    )
    return text, n1, n2


def fix_yield(text):
    return re.subn(r"^(\s*)yield\(\)\s*$", r"\1await get_tree().process_frame", text, flags=re.M)


def main():
    for rel in FILES:
        path = ROOT / rel
        text = path.read_text()
        lines = text.splitlines(keepends=True)
        lines, nb = fix_velocity_block(lines)
        text = "".join(lines)
        text, nshadow = fix_shadow_velocity(text)
        text, ncall, nconn = fix_callable_calls(text)
        text, nyield = fix_yield(text)
        path.write_text(text)
        print(
            f"{rel}: velocity_blocks={nb} shadow_removed={nshadow} "
            f"callable_fixed={ncall} connect_fixed={nconn} yield_fixed={nyield}"
        )


if __name__ == "__main__":
    main()
