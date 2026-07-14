# NeuroGolf Task Family Inventory

- Base: `/Users/giovannidallolio/workspace/kaggle_competitions/competitions/neurogolf-2026/submissions/exact-rewrite-pass-v3-validated/submission.zip`
- Tasks: `400`
- Repeated semantic families: `58`

## Highest Aggregate-Cost Families

| Family | Tasks | Known aggregate cost | Primitive tags | Architectures |
| --- | ---: | ---: | --- | --- |
| family_003 | 14 | 120582 | same_shape;paint_or_fill | bitwise;mixed;single_einsum |
Tasks: task024;task066;task076;task086;task092;task101;task132;task133;task224;task237;task243;task284;task286;task379
| family_001 | 18 | 84743 | same_shape;palette_add;paint_or_fill | bitwise;einsum;mixed;single_conv;single_einsum;spatial |
Tasks: task002;task090;task105;task145;task148;task176;task198;task220;task232;task246;task251;task258;task278;task303;task335;task349;task350;task352
| family_007 | 10 | 48455 | same_shape;palette_add;paint_or_fill | bitwise;mixed;single_conv;single_einsum;spatial |
Tasks: task055;task063;task151;task166;task187;task204;task256;task348;task357;task367
| family_006 | 13 | 45376 | same_shape;paint_or_fill | index_scatter;mixed;single_conv;single_einsum;single_gather |
Tasks: task013;task082;task113;task117;task137;task141;task248;task285;task288;task306;task328;task378;task382
| family_002 | 16 | 40386 | same_shape;paint_or_fill | bitwise;index_scatter;mixed;single_einsum;spatial |
Tasks: task007;task017;task028;task041;task061;task099;task165;task191;task212;task214;task305;task322;task333;task345;task356;task363
| family_009 | 8 | 34086 | same_shape;paint_or_fill | index_scatter;mixed |
Tasks: task009;task051;task080;task197;task280;task297;task358;task383
| family_042 | 2 | 34050 | crop_or_extract;select_or_erase;extract_and_recompose | mixed;quantized |
Tasks: task184;task233
| family_008 | 8 | 27986 | same_shape;mask_preserving;palette_add | index_scatter;mixed;quantized;single_conv;single_einsum;spatial |
Tasks: task077;task118;task120;task252;task279;task292;task320;task332
| family_015 | 6 | 26970 | same_shape;mask_preserving | index_scatter;mixed |
Tasks: task064;task158;task203;task293;task324;task370
| family_036 | 3 | 24877 | same_shape;mask_preserving | index_scatter;single_conv;single_einsum |
Tasks: task054;task314;task373
| family_013 | 6 | 23471 | same_shape;palette_add;paint_or_fill | mixed;spatial |
Tasks: task042;task043;task119;task219;task255;task273
| family_005 | 13 | 22943 | same_shape;paint_or_fill | index_scatter;mixed;quantized;single_gather;spatial |
Tasks: task005;task012;task020;task037;task089;task136;task168;task181;task190;task217;task225;task240;task385
| family_004 | 13 | 17703 | same_shape;palette_add;paint_or_fill | bitwise;mixed;quantized;single_conv;single_einsum;spatial |
Tasks: task047;task060;task095;task139;task162;task265;task299;task331;task341;task369;task381;task392;task397
| family_057 | 2 | 14005 | same_shape;paint_or_fill | index_scatter;mixed |
Tasks: task173;task215
| family_033 | 3 | 13121 | same_shape;paint_or_fill | index_scatter;mixed |
Tasks: task110;task175;task343
| family_043 | 2 | 12065 | crop_or_extract;select_or_erase;extract_and_recompose | mixed |
Tasks: task096;task377
| family_011 | 6 | 11896 | same_shape;mask_preserving | mixed;quantized;spatial |
Tasks: task010;task169;task277;task283;task330;task374
| family_051 | 2 | 11057 | same_shape;palette_filter;select_or_erase | index_scatter;mixed |
Tasks: task071;task074
| family_016 | 5 | 10294 | same_shape;mask_preserving;palette_add | einsum;mixed;single_conv;spatial |
Tasks: task070;task094;task125;task156;task294
| family_021 | 4 | 8951 | same_shape | einsum;mixed |
Tasks: task078;task154;task250;task270

## Expensive-Task Neighbors

### task233
- `task184` similarity `1.000000`, cost `2039`, tags `crop_or_extract;select_or_erase;extract_and_recompose`
- `task096` similarity `0.944444`, cost `7678`, tags `crop_or_extract;select_or_erase;extract_and_recompose`
- `task377` similarity `0.944444`, cost `4387`, tags `crop_or_extract;select_or_erase;extract_and_recompose`
- `task238` similarity `0.888889`, cost `1935`, tags `crop_or_extract;extract_and_recompose`
- `task325` similarity `0.888889`, cost `1483`, tags `crop_or_extract;select_or_erase;extract_and_recompose`

### task366
- `task170` similarity `0.805556`, cost `2124`, tags `crop_or_extract;select_or_erase`
- `task178` similarity `0.777778`, cost `762`, tags `select_or_erase`
- `task065` similarity `0.722222`, cost `638`, tags `crop_or_extract;subgrid_extract;select_or_erase`
- `task025` similarity `0.694444`, cost `9817`, tags `same_shape;select_or_erase`
- `task329` similarity `0.694444`, cost `1050`, tags `same_shape;select_or_erase`

### task286
- `task133` similarity `1.000000`, cost `21135`, tags `same_shape;paint_or_fill`
- `task101` similarity `1.000000`, cost `13695`, tags `same_shape;paint_or_fill`
- `task076` similarity `1.000000`, cost `12825`, tags `same_shape;paint_or_fill`
- `task243` similarity `1.000000`, cost `10690`, tags `same_shape;paint_or_fill`
- `task066` similarity `1.000000`, cost `10571`, tags `same_shape;paint_or_fill`

### task054
- `task314` similarity `1.000000`, cost `100`, tags `same_shape;mask_preserving`
- `task373` similarity `1.000000`, cost `60`, tags `same_shape;mask_preserving`
- `task064` similarity `0.888889`, cost `10432`, tags `same_shape;mask_preserving`
- `task324` similarity `0.888889`, cost `8555`, tags `same_shape;mask_preserving`
- `task370` similarity `0.888889`, cost `6585`, tags `same_shape;mask_preserving`

### task133
- `task286` similarity `1.000000`, cost `26909`, tags `same_shape;paint_or_fill`
- `task101` similarity `1.000000`, cost `13695`, tags `same_shape;paint_or_fill`
- `task076` similarity `1.000000`, cost `12825`, tags `same_shape;paint_or_fill`
- `task243` similarity `1.000000`, cost `10690`, tags `same_shape;paint_or_fill`
- `task066` similarity `1.000000`, cost `10571`, tags `same_shape;paint_or_fill`

### task285
- `task328` similarity `1.000000`, cost `6296`, tags `same_shape;paint_or_fill`
- `task382` similarity `1.000000`, cost `5695`, tags `same_shape;paint_or_fill`
- `task117` similarity `1.000000`, cost `3795`, tags `same_shape;paint_or_fill`
- `task137` similarity `1.000000`, cost `3389`, tags `same_shape;paint_or_fill`
- `task378` similarity `1.000000`, cost `3091`, tags `same_shape;paint_or_fill`

### task187
- `task367` similarity `1.000000`, cost `13926`, tags `same_shape;palette_add;paint_or_fill`
- `task204` similarity `1.000000`, cost `10232`, tags `same_shape;palette_add;paint_or_fill`
- `task256` similarity `1.000000`, cost `2113`, tags `same_shape;palette_add;paint_or_fill`
- `task055` similarity `1.000000`, cost `1767`, tags `same_shape;palette_add;paint_or_fill`
- `task063` similarity `1.000000`, cost `1706`, tags `same_shape;palette_add;paint_or_fill`

### task349
- `task002` similarity `1.000000`, cost `14285`, tags `same_shape;palette_add;paint_or_fill`
- `task145` similarity `1.000000`, cost `12855`, tags `same_shape;palette_add;paint_or_fill`
- `task198` similarity `1.000000`, cost `10350`, tags `same_shape;palette_add;paint_or_fill`
- `task350` similarity `1.000000`, cost `9036`, tags `same_shape;palette_add;paint_or_fill`
- `task148` similarity `1.000000`, cost `4887`, tags `same_shape;palette_add;paint_or_fill`

### task002
- `task349` similarity `1.000000`, cost `14892`, tags `same_shape;palette_add;paint_or_fill`
- `task145` similarity `1.000000`, cost `12855`, tags `same_shape;palette_add;paint_or_fill`
- `task198` similarity `1.000000`, cost `10350`, tags `same_shape;palette_add;paint_or_fill`
- `task350` similarity `1.000000`, cost `9036`, tags `same_shape;palette_add;paint_or_fill`
- `task148` similarity `1.000000`, cost `4887`, tags `same_shape;palette_add;paint_or_fill`

### task367
- `task187` similarity `1.000000`, cost `15790`, tags `same_shape;palette_add;paint_or_fill`
- `task204` similarity `1.000000`, cost `10232`, tags `same_shape;palette_add;paint_or_fill`
- `task256` similarity `1.000000`, cost `2113`, tags `same_shape;palette_add;paint_or_fill`
- `task055` similarity `1.000000`, cost `1767`, tags `same_shape;palette_add;paint_or_fill`
- `task063` similarity `1.000000`, cost `1706`, tags `same_shape;palette_add;paint_or_fill`

