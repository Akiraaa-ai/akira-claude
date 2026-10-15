# MAZGAL (Godot 4)

Oyun artık Godot 4 ile yapılıyor. Steam'e masaüstü oyun olarak çıkacak. Dosya boyutu sınırı yok ve modeller sıkıştırılmıyor.

## Açmak
1. Godot 4.7'ü indir (ücretsiz): https://godotengine.org/download (Windows, "Godot Engine", .NET olmayan sürüm).
2. Godot'u aç, **Import** de, bu klasördeki `project.godot` dosyasını seç.
3. **F5** ile oyun başlar.

## Kontroller
WASD yürü, Shift koş, Ctrl eğil, F fener, Esc fareyi bırakır.

## Dosyaları nereye atacaksın
- **3D modeller** (`.glb`, `.gltf`, `.fbx`, `.blend`): `modeller/` klasörüne at. Godot onları kendisi içe alır ve oldukları gibi 3D kalırlar.
- **Sesler** (`.mp3`, `.wav`, `.ogg`): `sesler/` klasörüne at.
- **Mixamo karakter ve animasyonlar**: `modeller/selim/` klasörüne at.

Attıktan sonra bana hangi dosyayı attığını yaz, ben oyuna bağlarım.

## Klasörler
- `sahneler/`: oyun sahneleri (`sokak.tscn` açılış sokağı)
- `kod/`: GDScript kodları
- `modeller/`: 3D modeller (`sehir.glb` senin şehrin, orijinal haliyle)
- `sesler/`: seslendirmeler ve müzikler
