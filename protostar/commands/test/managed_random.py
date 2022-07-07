from contextlib import contextmanager
from contextvars import ContextVar
from random import Random

_contextvar: ContextVar[Random] = ContextVar("managed_random")


@contextmanager
def managed_random(seed=None) -> Random:
    random = Random(seed)
    token = _contextvar.set(random)
    try:
        yield random
    finally:
        _contextvar.reset(token)


def current_managed_random() -> Random:
    return _contextvar.get()
