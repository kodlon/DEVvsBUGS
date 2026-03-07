## Конфіг скіла "Rubber Duck Aura" (Пасивний)
extends Node

const SKILL_NAME   = "Stepico Aura"
const DESCRIPTION  = "Усі вражені від того, що ВИ працюєте в STEPICO: сповільнює та пошкоджує баги."

const AURA_RANGE    := 120.0   # пікселів — радіус зони
const AURA_SLOWDOWN := 1     # множник швидкості ворогів (0.7 = на 30% повільніше)
const AURA_DPS      := 7.5     # шкода за секунду ворогам в зоні
