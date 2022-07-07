from random import Random
from typing import List

import pytest

from protostar.commands.test.managed_random import (
    managed_random,
    current_managed_random,
)


def test_setting_seed_gives_reproducible_results():
    seed = 100

    with managed_random(seed) as random:
        rand_a = k_uniforms(random)

    with managed_random(seed) as random:
        rand_b = k_uniforms(random)

    assert rand_a == rand_b


def test_seed_argument_can_be_omitted():
    with managed_random() as random:
        rand_a = k_uniforms(random)

    with managed_random(seed=None) as random:
        rand_b = k_uniforms(random)

    assert rand_a != rand_b


def test_current_managed_random():
    with managed_random():
        with managed_random() as expected_random:
            actual_random = current_managed_random()
            assert expected_random is actual_random


def test_current_managed_random_raises_outside_context_manager():
    with pytest.raises(LookupError):
        current_managed_random()


def k_uniforms(random: Random, k: int = 32) -> List[float]:
    return [random.uniform(0, 2048) for _ in range(k)]
