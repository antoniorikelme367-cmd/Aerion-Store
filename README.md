# Aerion — loja e aluguel de drones (Flutter)

Como rodar:

    flutter create . --project-name aerion_store --platforms=android,ios,web
    rm -rf test
    flutter pub get
    flutter run            # ou: flutter run -d chrome

`flutter create .` só adiciona as pastas de plataforma; ele não sobrescreve `lib/`, `pubspec.yaml` nem `assets/`.
A fonte Sora é baixada em tempo de execução pelo pacote google_fonts (precisa de internet na primeira abertura).
