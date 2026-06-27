# Сессия: 2026-06-27 | Настройка WORKSPACE

**Агент:** Claude (реструктуризация)
**Продукт/область:** Системная архитектура
**Статус:** завершено

## Что было сделано

1. Создана структура `C:\Users\user\Documents\WORKSPACE\`
2. Перенесено содержимое `Desktop\MyBusiness\` → `WORKSPACE\`
3. Восстановлена `projects\Редизайн_сайта\` из теневой копии Windows (16.06.2026)
4. Перенесены разработки: `Разработки\Сайт Ангел\` → `products\angel-site\`
5. Перенесены разработки: `Разработки\Saas Расчет\` → `products\monument-saas\`
6. Созданы папки `memory\` и `agents\` со структурой
7. Обновлён `CLAUDE.md` под новые пути

## Финальная структура WORKSPACE

```
WORKSPACE/
├── knowledge-base/       ← база знаний бизнеса
├── products/
│   ├── angel-site/       ← сайт angel.su (задеплоен на Бегет)
│   ├── monument-saas/    ← программа расчёта заказа
│   └── _future/
├── projects/             ← бизнес-проекты
│   ├── CRM/
│   ├── Карточка_Яндекс_Карты/
│   ├── Мобильный_офис/
│   └── Редизайн_сайта/
├── agents/
│   ├── hermes/
│   └── sales-dept/
├── memory/               ← память агентов
│   ├── log.md
│   ├── decisions.md
│   └── sessions/
├── content/
├── raw/
├── inbox/
└── _archive/
```

## Следующие шаги

- [ ] Перенаправить Obsidian vault на `WORKSPACE\`
- [ ] Инициализировать git и создать GitHub репо
- [ ] Настроить синхронизацию с VPS
- [ ] Создать `agents/hermes/prompt.md`
