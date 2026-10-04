# GamepadMaps

Addon de mapa para o **WoW Forever** (cliente 1.60.1, `Interface: 16001`) feito para não quebrar a interface nativa de gamepad.

Muitos addons causam `ADDON_ACTION_BLOCKED` ao abrir ou fechar o mapa com o controle, porque o código deles executa dentro do caminho seguro da UI de gamepad da Blizzard (por exemplo, pins registrados no data provider do mapa e uso do `GameTooltip` compartilhado). Este addon evita isso por construção.

## Regras anti-taint

1. Nunca registrar pins em data providers da Blizzard. Os marcadores são frames próprios.
2. Nunca substituir funções nem escrever em tabelas da Blizzard.
3. Tooltip próprio (`GamepadMapsTooltip`), nunca o `GameTooltip` compartilhado.
4. Registro de eventos protegido por `pcall`.
5. Todo evento `ADDON_ACTION_BLOCKED` e `ADDON_ACTION_FORBIDDEN` é gravado em `/gm log`, mesmo sem debug.

## Funcionalidades (v0.1.0)

- Coordenadas do jogador e do cursor no mapa.
- Opacidade do mapa (teclado e mouse; desligada por padrão com gamepad).
- Notas próprias no mapa, com marcadores, tooltip e waypoint.
- Teclas atribuíveis ao controle em *Opções > Teclas > AddOns > GamepadMaps*:
  adicionar nota, próxima/anterior nota, waypoint na nota, apagar nota.

Comandos: `/gm` mostra a ajuda. Principais: `/gm note [nome]`, `/gm list`, `/gm clear`, `/gm coords`, `/gm opacity 0.3-1`, `/gm debug on|off`, `/gm log`.

## Instalação

Copie a pasta `GamepadMaps/` (a que contém o `.toc`) para:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

Use `/reload` no jogo depois de cada atualização. Ative os erros de Lua com `/console scriptErrors 1`.

## Checklist de teste (precisa do cliente)

1. O addon carrega sem erros de Lua.
2. Abrir e fechar o mapa pelo gamepad **sem** `ADDON_ACTION_BLOCKED` (rode `/gm debug on` antes).
3. As coordenadas do jogador e do cursor aparecem. Verifique se o cursor virtual do gamepad atualiza a coordenada do cursor.
4. `/gm note` cria um marcador; ele fica no lugar certo ao dar zoom.
5. As teclas do addon podem ser atribuídas a botões do controle e funcionam com o mapa aberto.
6. `/gm log` mostra `GAME_PAD_ACTIVE_CHANGED` ao alternar entre controle e teclado.

Se algo falhar, copie o texto exato do erro e o resultado de `/gm log`.

## Desenvolvimento

Teste de fumaça com a API do WoW simulada (não substitui o teste no cliente):

```
lua5.4 tests/run.lua
```

## Próximos passos

- Revelar áreas não exploradas (estilo Leatrix Maps).
- Base de marcadores (raros, tesouros, pontos de voo) e filtros por categoria.
- Painel lateral navegável pelo direcional.
- Compatibilidade com a API de plugins do HandyNotes.
