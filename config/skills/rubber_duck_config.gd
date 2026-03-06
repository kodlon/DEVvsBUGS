## Конфіг скіла "Rubber Duck Aura" (Пасивний)
extends Node

const SKILL_NAME   = "Rubber Duck Aura"
const DESCRIPTION  = "Гумова качечка захищає зону навколо тебе: сповільнює та пошкоджує баги."

const AURA_RANGE    := 120.0   # пікселів — радіус зони
const AURA_SLOWDOWN := 0.7     # множник швидкості ворогів (0.7 = на 30% повільніше)
const AURA_DPS      := 5.0     # шкода за секунду ворогам в зоні
