# Балансировка экономики

## 1. Апгрейды
Стоимость = `ceil(base_cost * pow(1.7, level-1))`
* base_cost определяется категорией (samogon: 1000; beer: 1500; wine: 2000)

## 2. Цена продажи
`sell_price = base * quality_multiplier * trend_mod`

| Качество | Множитель |
|----------|-----------|
| 0 ⭐ | 1.0 |
| 1 ⭐ | 1.3 |
| 2 ⭐ | 1.6 |
| 3 ⭐ | 2.0 |

## 3. Репутация
Репутация + `floor(price / 50)`, если удовлетворены требования клиента.
Штраф − `10` при провале заказа или полиции.

## 4. Алгоритм предложения клиентов
```pseudo
chance = clamp((reputation / 200), 0.05, 0.6)
if randf() < chance:
    pick rich
elif randf() < 0.4:
    pick middle
else:
    pick poor
```

## 5. Таймеры инструментов
По умолчанию: Fermentation 10 с, Distiller 20 с… Рекомендация: умножать base × (1 – 0.05×tool_level).
