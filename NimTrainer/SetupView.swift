import SwiftUI

struct SetupView: View {
    @State private var settings = GameSettings()
    @State private var goGame     = false
    @State private var goTraining = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                modeSection
                misereToggle
                pilesSection
                if settings.gameMode == .training {
                    trainingLevelSection
                } else {
                    playersSection
                }
                startButton
            }
            .padding()
        }
        .background(Color.nimBackground.ignoresSafeArea())
        .navigationTitle("Nim Trainer")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $goGame)     { GameView(settings: settings) }
        .navigationDestination(isPresented: $goTraining) { TrainingView(settings: settings) }
    }

    // MARK: – Game mode

    var modeSection: some View {
        card {
            VStack(spacing: 0) {
                sectionLabel("Режим игры")
                VStack(spacing: 8) {
                    ForEach(GameMode.allCases) { mode in
                        modeRow(mode)
                    }
                }
            }
        }
    }

    func modeRow(_ mode: GameMode) -> some View {
        Button { settings.gameMode = mode } label: {
            HStack {
                Text(mode.rawValue).foregroundColor(settings.gameMode == mode ? .black : .white)
                Spacer()
                if settings.gameMode == mode {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.black)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(settings.gameMode == mode ? Color.yellow : Color.nimCardDark)
            .cornerRadius(10)
        }
    }

    // MARK: – Misere

    var misereToggle: some View {
        card {
            Toggle(isOn: $settings.isMisere) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Обратный Ним (misère)").font(.headline).foregroundColor(.white)
                    Text(settings.isMisere ? "Кто взял последний — проиграл"
                                           : "Кто взял последний — выиграл")
                        .font(.caption).foregroundColor(.gray)
                }
            }.tint(.yellow)
        }
    }

    // MARK: – Piles

    var pilesSection: some View {
        card {
            VStack(spacing: 14) {
                sectionLabel("Кучки")

                stepperRow(label: "Количество кучек", value: settings.pileCount, range: 2...10) {
                    settings.setPileCount($0)
                }

                Divider().background(Color.gray.opacity(0.3))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Диапазон случайных: \(settings.randomMin)–\(settings.randomMax)")
                        .font(.caption).foregroundColor(.gray)
                    HStack {
                        Text("От").frame(width: 28).foregroundColor(.gray)
                        Slider(value: Binding(get: { Double(settings.randomMin) },
                                              set: { settings.randomMin = Int($0) }),
                               in: 1...30, step: 1).tint(.yellow)
                    }
                    HStack {
                        Text("До").frame(width: 28).foregroundColor(.gray)
                        Slider(value: Binding(get: { Double(settings.randomMax) },
                                              set: { settings.randomMax = max(Int($0), settings.randomMin) }),
                               in: 1...63, step: 1).tint(.yellow)
                    }
                }

                Button {
                    settings.randomizePiles()
                } label: {
                    Label("Сгенерировать случайно", systemImage: "shuffle")
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Color.yellow.opacity(0.15))
                        .foregroundColor(.yellow).cornerRadius(10)
                }

                Divider().background(Color.gray.opacity(0.3))

                ForEach(settings.pileSizes.indices, id: \.self) { i in
                    HStack {
                        Text("Кучка \(i + 1)").foregroundColor(.white).frame(width: 80, alignment: .leading)
                        Spacer()
                        Stepper(value: Binding(get: { settings.pileSizes[i] },
                                               set: { settings.pileSizes[i] = max(1, $0) }),
                                in: 1...63) {
                            Text("\(settings.pileSizes[i])").foregroundColor(.yellow).frame(width: 36)
                        }
                    }
                }
            }
        }
    }

    // MARK: – Players

    var playersSection: some View {
        card {
            VStack(spacing: 14) {
                sectionLabel("Игроки")

                stepperRow(label: "Количество игроков", value: settings.playerCount, range: 2...5) {
                    settings.setPlayerCount($0)
                }

                Divider().background(Color.gray.opacity(0.3))

                ForEach($settings.players) { $player in
                    PlayerConfigRow(player: $player)
                    if player.id < settings.players.count {
                        Divider().background(Color.gray.opacity(0.2))
                    }
                }
            }
        }
    }

    // MARK: – Training level

    var trainingLevelSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Уровень тренировки")
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { lvl in
                        Button { settings.trainingLevel = lvl } label: {
                            VStack(spacing: 3) {
                                Text("Ур. \(lvl)").font(.caption.bold())
                                Text("до \([0, 7, 15, 31, 63][lvl])").font(.caption2)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(settings.trainingLevel == lvl ? Color.yellow : Color.nimCardDark)
                            .foregroundColor(settings.trainingLevel == lvl ? .black : .gray)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: – Start

    var startButton: some View {
        Button {
            if settings.gameMode == .training { goTraining = true } else { goGame = true }
        } label: {
            Text("Начать игру").font(.title3.bold())
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Color.yellow).foregroundColor(.black).cornerRadius(16)
        }
        .padding(.top, 4)
    }

    // MARK: – Helpers

    func stepperRow(label: String, value: Int, range: ClosedRange<Int>, onSet: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(label).foregroundColor(.white)
            Spacer()
            Stepper(value: Binding(get: { value }, set: onSet), in: range) {
                Text("\(value)").foregroundColor(.yellow).frame(width: 28)
            }
        }
    }

    @ViewBuilder
    func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.nimCard)
            .cornerRadius(16)
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text).font(.subheadline.bold()).foregroundColor(.secondary)
            .textCase(.uppercase).frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
    }
}

// MARK: – Player config row

struct PlayerConfigRow: View {
    @Binding var player: PlayerConfig

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: player.isBot ? "cpu" : "person.fill")
                    .foregroundColor(player.isBot ? .cyan : .yellow)
                TextField("Имя", text: $player.name).foregroundColor(.white)
                Spacer()
                Toggle("Бот", isOn: $player.isBot).labelsHidden().tint(.cyan)
            }
            if player.isBot {
                Picker("Сложность", selection: $player.botDifficulty) {
                    ForEach(BotDifficulty.allCases) { d in Text(d.rawValue).tag(d) }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
