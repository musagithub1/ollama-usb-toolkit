#!/usr/bin/env python3
"""Sandboxed math evaluator (AST whitelist). Stdlib only."""
import ast
import math
import operator as op
import sys

OPS = {
    ast.Add: op.add, ast.Sub: op.sub, ast.Mult: op.mul,
    ast.Div: op.truediv, ast.FloorDiv: op.floordiv,
    ast.Mod: op.mod, ast.Pow: op.pow,
    ast.USub: op.neg, ast.UAdd: op.pos,
}


def _eval(node):
    if isinstance(node, ast.Expression):
        return _eval(node.body)
    if isinstance(node, ast.Constant):
        if isinstance(node.value, (int, float)):
            return node.value
        raise ValueError("only numeric constants allowed")
    if isinstance(node, ast.BinOp) and type(node.op) in OPS:
        return OPS[type(node.op)](_eval(node.left), _eval(node.right))
    if isinstance(node, ast.UnaryOp) and type(node.op) in OPS:
        return OPS[type(node.op)](_eval(node.operand))
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
        if isinstance(node.func.value, ast.Name) and node.func.value.id == "math":
            fn = getattr(math, node.func.attr, None)
            if callable(fn):
                return fn(*(_eval(a) for a in node.args))
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
        fn = getattr(math, node.func.id, None)
        if callable(fn):
            return fn(*(_eval(a) for a in node.args))
    if isinstance(node, ast.Name) and node.id in {"pi", "e", "tau", "inf", "nan"}:
        return getattr(math, node.id)
    if (isinstance(node, ast.Attribute)
            and isinstance(node.value, ast.Name)
            and node.value.id == "math"
            and isinstance(getattr(math, node.attr, None), (int, float))):
        return getattr(math, node.attr)
    raise ValueError(f"unsupported expression element: {ast.dump(node)}")


def evaluate(expr: str):
    tree = ast.parse(expr, mode="eval")
    return _eval(tree)


if __name__ == "__main__":
    expr = " ".join(sys.argv[1:]) or "2+2"
    try:
        print(evaluate(expr))
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)
