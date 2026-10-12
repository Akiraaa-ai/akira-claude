# Vaka JSON şeması

Her vaka `assets/cases/<id>.json` dosyasıdır. Uygulama bu klasördeki tüm `.json` dosyalarını açılışta bulur ve `order` alanına göre sıralar. Hatalı vaka (eksik alan, bilinmeyen kimlik) listeye alınmaz; `flutter test` de bunu yakalar.

Tam bir örnek: `test/fixtures/ornek_vaka.json`.

Görsel ve ses alanlarına **uzantısız dosya adı** yazılır (`"image": "vaka_01_sahne_salon"` → `assets/images/vaka_01_sahne_salon.png|jpg|webp`).

## Üst düzey

| Alan | Tür | Açıklama |
|---|---|---|
| `schemaVersion` | sayı | Şu an `1` |
| `id` | metin | Benzersiz vaka kimliği, dosya adıyla aynı olması önerilir |
| `order` | sayı | Listede sıra |
| `title`, `subtitle`, `summary` | metin | Vaka seçimi kartı |
| `briefing` | metin | Olay özeti (defterin başında) |
| `coverImage` | görsel | Kapak (varsayılan `<id>_kapak`) |
| `freeHints` | sayı | Reklamsız ipucu hakkı (varsayılan 0). Bitince ipucu ödüllü reklamla alınır |
| `access` | nesne | `{"free": true}` ya da `{"free": false, "packId": "vaka_paketi_1"}` |
| `music` | nesne | `investigation`, `tension` (suçlama ekranı), `finale` ses adları |
| `intro` | nesne | Giriş sahnesi (isteğe bağlı) |
| `scenes`, `suspects`, `clues`, `interrogations` | liste | Aşağıda |
| `solution` | nesne | Çözüm ve final |
| `wrongAnswer` | nesne | Yanlış suçlama sahnesi |
| `connections`, `timeline`, `stars` | liste / nesne | Delil panosu, zaman çizelgesi, yıldız eşikleri (isteğe bağlı, aşağıda) |

## `scenes[]`
`id`, `title`, `image`, `description`, `rain` (true ise sahnede yağmur yağar).

## `suspects[]`
`id`, `name`, `role`, `statement` (ilk ifade), `portrait`, `description` (isteğe bağlı).

## `clues[]`
| Alan | Açıklama |
|---|---|
| `id`, `title`, `description` | |
| `sceneId` | İpucunun bulunduğu sahne. **Boş bırakılırsa** ipucu sahnede değildir, bir çelişkiyle ya da `unlockedByClueIds` ile açılır |
| `unlockedByClueIds` | Bu ipuçlarının hepsi bulununca ipucu kendiliğinden deftere eklenir (ör. laboratuvar sonucu) |
| `area` | Dokunma alanı, sahne görselinin oranı olarak: `{"x":0.1,"y":0.5,"w":0.2,"h":0.1}` (sol üst köşe + genişlik/yükseklik, 0–1) |
| `suspectIds` | Bağlantılı şüpheliler |
| `image` | İsteğe bağlı yakın çekim görseli |
| `needsMagnifier` | `true` ise ipucu ancak büyüteç üzerindeyken alınır (küçük ayrıntılar için) |

## `interrogations[]`
| Alan | Açıklama |
|---|---|
| `id`, `suspectId`, `question`, `answer` | |
| `requiresClueIds` | Soru ancak bu ipuçları bulununca görünür |
| `contradiction` | `{"clueId": "...", "text": "...", "unlocksClueId": "..."}`: oyuncu bu cevaba `clueId` ipucunu sunarsa çelişki açılır, `text` gösterilir, varsa `unlocksClueId` deftere eklenir. Birden çok kanıt gerekiyorsa `"clueIds": ["a", "b"]` yazılır: hepsi defterdeyken biri sunulunca açılır |

## `solution`
| Alan | Açıklama |
|---|---|
| `culpritId` | Suçlu |
| `reasonOptions` | "Neden?" seçenekleri: `[{"id":"r1","text":"..."}]` |
| `correctReasonId` | Doğru gerekçe. Vaka, kişi **ve** gerekçe doğruysa çözülür |
| `explanation` | Kısa açıklama |
| `deductionChain` | Çıkarım zinciri adımları (metin listesi) |
| `finale` | `{"title": "...", "paragraphs": ["..."], "image": "..."}` |
| `evidence` | İsteğe bağlı kanıt adımı: `{"clueIds": ["a","b","c"], "pick": 2}`. Oyuncu defterinden `pick` kanıt seçer, hepsi `clueIds` içinde olmalı. Vaka kişi + gerekçe + kanıt doğruysa çözülür |

## `wrongAnswer`
`title`, `paragraphs` (yanlış kişi seçilince), `wrongReasonText` (kişi doğru, gerekçe yanlışsa; isteğe bağlı), `wrongEvidenceText` (kişi ve gerekçe doğru, kanıt yanlışsa; isteğe bağlı), `image`, `hintPenalty` (her yanlış suçlamada eksilen ipucu hakkı), `penaltyPoints` (her yanlış suçlamada eklenen ceza puanı, varsayılan 1).

## `connections[]`: delil panosu
Panoda iki ipucu iple bağlanınca açılan çıkarımlar: `{"id": "b1", "clueIds": ["a", "b"], "deductionStep": 2}`. Metin `deductionStep` ile `solution.deductionChain` içinden (1'den başlar) alınır; istenirse doğrudan `"text"` yazılır. Liste boşsa Pano sekmesi görünmez.

## `timeline`: zaman çizelgesi
`{"slots": ["21:05", "21:10"], "events": [...]}`. Her olay: `id`, `text`, `time` (doğru saat, `slots` içinden), `suspectId` ve `place` (kartın başlığı, isteğe bağlı), `requiresClueIds` (kart ancak bu ipuçları bulununca gelir). Oyuncu kartları saatlere yerleştirir; tüm kartlar açık ve doğru saatteyse çizelge çözülür. Yoksa Zaman sekmesi görünmez.

## `stars`: yıldız eşikleri
`{"three": 0, "two": 2}`. Ceza = kullanılan ipucu yardımı + yanlış suçlama puanı. Ceza `three` değerini aşmazsa 3, `two` değerini aşmazsa 2, aksi halde 1 yıldız. Toplam yıldız dedektif rütbesini belirler (Çaylak → Başkomiser).

Doğrulama, her ipucunun oyunda bir yolla (sahne, çelişki ya da otomatik açılma) elde edilebildiğini de kontrol eder.

## `intro`: giriş sahnesi zaman çizelgesi
`durationMs` (sahne toplam süresi), `background`, `rain`, `events[]`. Her olayın `atMs` (başlangıçtan milisaniye) ve `type` alanı vardır:

| `type` | Diğer alanlar | Ne yapar |
|---|---|---|
| `text` | `text`, `speaker` | Ekrana daktilo efektiyle satır yazar |
| `voice` | `sound` | Seslendirme dosyasını çalar |
| `sfx` | `sound` | Ses efekti çalar |
| `music` / `stopMusic` | `sound` | Müziği başlatır / durdurur |
| `shake` | `value` (şiddet, px) | Ekranı titretir |
| `flash` | | Şimşek gibi beyaz parlama |
| `background` | `image` | Arka planı yumuşak geçişle değiştirir |
| `rain` | `value` (0/1) | Yağmuru kapatır/açar |

Zaman çizelgesi sesten bağımsız kendi saatiyle akar: ses dosyası olmasa da sahne aynı zamanlamayla oynar. Oyuncu "Atla" ile geçebilir.
