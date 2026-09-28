/// The two remaining app tabs. Selection stays local to `ContentView`.
private enum StudioTab: String, CaseIterable, Identifiable {
    case aims
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aims: return "Aims"
        case .home: return "Home"
        }
    }

    var symbol: String {
        switch self {
        case .aims: return "scope"
        case .home: return "house.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    // Retained so the existing patch-draft navigation hooks keep working.
    @State private var tabNavigation: AppTabNavigationState
    @State private var selectedTab: StudioTab
    @AppStorage("bypass7.ui.theme.dark") private var isDarkTheme = true
    @State private var showSettings = false
    @State private var showLogs = false

    init() {
#if targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let simulatingInject = arguments.contains("--simulate-inject-tab")
        _tabNavigation = State(
            initialValue: AppTabNavigationState(
                selectedTab: simulatingInject ? AppSection.patches.rawValue : AppSection.home.rawValue
            )
        )
        _selectedTab = State(initialValue: simulatingInject ? .aims : .home)
#else
        _tabNavigation = State(initialValue: AppTabNavigationState())
        _selectedTab = State(initialValue: .home)
#endif
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                studioHeader

                Group {
                    switch selectedTab {
                    case .home:
                        DashboardView()
                    case .aims:
                        PatchProjectsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                studioTabBar
            }
        }
        .tint(AppTheme.accent)
        .imageScale(.small)
        .preferredColorScheme(isDarkTheme ? .dark : .light)
        .animation(.easeInOut(duration: AppTheme.motionDuration), value: isDarkTheme)
        .onChange(of: patchDraftCoordinator.request?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onChange(of: patchDraftCoordinator.importRequest?.id) { requestID in
            if requestID != nil { tabNavigation.select(AppSection.patches.rawValue) }
        }
        .onAppear {
            tabNavigation.reconcileSelection(with: featureVisibility)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showLogs) { LogView() }
    }

    // MARK: Header

    private var studioHeader: some View {
        HStack(spacing: 12) {
            AppAvatar(size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(selectedTab.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text("BYPASS7 PROXY")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.4)
                    .foregroundStyle(AppTheme.accent)
            }

            Spacer(minLength: 8)

            Button {
                isDarkTheme.toggle()
            } label: {
                Image(systemName: isDarkTheme ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.surface, in: Circle())
                    .overlay(Circle().strokeBorder(AppTheme.surfaceBorder, lineWidth: 1))
            }
            .buttonStyle(AppPressableButtonStyle())
            .accessibilityLabel(isDarkTheme ? "Ativar tema claro" : "Ativar tema escuro")
        }
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.surfaceBorder)
                .frame(height: 0.5)
        }
    }

    // MARK: Tab bar

    private var studioTabBar: some View {
        HStack(spacing: 4) {
            ForEach(StudioTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: AppTheme.motionDuration)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 17, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(isSelected ? AppTheme.accent : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        isSelected ? AppTheme.accentSoft : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.surfaceBorder)
                .frame(height: 0.5)
        }
    }

    // MARK: Feature visibility (retained for the navigation hooks)

    private var featureVisibility: FeatureVisibility {
        let cleaner = UserDefaults.standard.bool(forKey: FeatureVisibility.cleanerStorageKey)
        let wallpapers = UserDefaults.standard.bool(forKey: FeatureVisibility.wallpapersStorageKey)
        let supported = WallpaperFeatureSupportPolicy.isSupported(major: AppInfo.versionTuple.major)
        return FeatureVisibility(cleanerEnabled: cleaner, wallpapersEnabled: wallpapers, wallpapersSupported: supported)
    }
}

/// Shared "game status" pill shown at the top of the feature tabs.
private struct GameStatusPill: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            Text("Free Fire Normal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text("· com.dts.freefireth")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppTheme.surface, in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).strokeBorder(AppTheme.surfaceBorder, lineWidth: 1))
    }
}

/// Visual-only "Aims" tab. No injection logic is wired here yet.
private struct AimsTabView: View {
    private enum FileKind: String, CaseIterable, Hashable {
        case avatar
        case cache

        var title: String {
            switch self {
            case .avatar: return "Avatar"
            case .cache: return "Cache"
            }
        }
    }

    @State private var fileKind: FileKind = .avatar
    @State private var hsGirafa = false
    @State private var hsCearense = false
    @State private var hsPescocoAntena = false
    @State private var hsPeitoAntena = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                GameStatusPill()

                AppCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SELECIONE O TIPO DE ARQUIVO")
                            .font(.footnote.weight(.bold))
                            .kerning(0.6)
                            .foregroundStyle(.secondary)

                        AppSegmentedControl(items: FileKind.allCases, selection: $fileKind) { $0.title }

                        switch fileKind {
                        case .avatar:
                            Text("Arquivos Avatar com ativação pelo botão Injetar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            avatarFunctions

                        case .cache:
                            cacheMaintenance
                        }
                    }
                }

                AppWarningBanner(
                    title: "FUNÇÕES AVATAR SÃO 100% SEGURAS E SEM RISCO SE FIZER O MÉTODO DE INJETAR CORRETAMENTE",
                    systemImage: "checkmark.shield.fill",
                    tint: .green
                )

                AppDisabledButton(title: "INJETAR (40%)", systemImage: "bolt.fill")
                    .padding(.top, 2)
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private var avatarFunctions: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                Text("FUNÇÕES AVATAR")
                    .font(.subheadline.weight(.bold))
                    .kerning(0.6)
                    .foregroundStyle(.primary)
            }

            AppCard(padding: 4) {
                VStack(spacing: 0) {
                    AppToggleRow(
                        title: "HS GIRAFA",
                        subtitle: "Função HS Girafa",
                        systemImage: "list.bullet",
                        isOn: $hsGirafa
                    )
                    .padding(.horizontal, 12)

                    separator

                    AppToggleRow(
                        title: "HS CEARENSE",
                        subtitle: "Função HS Cearense",
                        systemImage: "scope",
                        isOn: $hsCearense
                    )
                    .padding(.horizontal, 12)

                    separator

                    AppToggleRow(
                        title: "HS PESCOÇO + ANTENA",
                        subtitle: "Pescoço com antena de mira na cabeça",
                        systemImage: "antenna.radiowaves.left.and.right",
                        isOn: $hsPescocoAntena
                    )
                    .padding(.horizontal, 12)

                    separator

                    AppToggleRow(
                        title: "HS PEITO + ANTENA",
                        subtitle: "Função de peito com antena",
                        systemImage: "antenna.radiowaves.left.and.right",
                        isOn: $hsPeitoAntena
                    )
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    private var separator: some View {
        Rectangle()
            .fill(AppTheme.surfaceBorder)
            .frame(height: 0.5)
    }

    private var cacheMaintenance: some View {
        VStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("EM MANUTENÇÃO")
                .font(.subheadline.weight(.bold))
                .kerning(1)
                .foregroundStyle(.secondary)
            Text("Esta área estará disponível em breve.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

private struct DashboardView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showLogs = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    deviceCard

                    Text(language.text("settings.supported_range_summary"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    discordLink
                        .padding(.top, 4)
                }
                .padding(.horizontal, AppTheme.pageInset)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .tint(AppTheme.accent)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLogs = true } label: {
                        Image(systemName: "apple.terminal")
                    }
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(language.text("accessibility.open_logs"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(language.text("accessibility.open_settings"))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .animation(.easeInOut(duration: AppTheme.motionDuration), value: appState.isSupported)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
        }
    }

    private var deviceCard: some View {
        AppCard(padding: 18) {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    AppRowIcon(systemName: "iphone", tint: AppTheme.accent, frameSize: 40)
                    Text(language.text("common.device"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 0) {
                    infoRow(
                        language.text("dashboard.hardware_model"),
                        value: AppInfo.displayMachineName
                    )

                    separator

                    infoRow(
                        language.text("settings.ios_version"),
                        value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))"
                    )

                    separator

                    HStack {
                        Text(language.text("settings.compatibility"))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    .font(.subheadline)
                    .padding(.vertical, 10)

                    if appState.kernelExploitApplicable && AppInfo.versionTuple.major < 26 {
                        separator

                        HStack {
                            Text(language.text("dashboard.kernel_status"))
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 8)
                            if appState.kernelExploitRunning {
                                ProgressView().controlSize(.small)
                            } else {
                                Text(language.text(appState.exploitStatus.isSuccess ? "dashboard.kernel_active" : "dashboard.kernel_inactive"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(appState.exploitStatus.isSuccess ? Color.green : Color.secondary)
                            }
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
        .padding(.vertical, 10)
    }

    private var separator: some View {
        Rectangle()
            .fill(AppTheme.surfaceBorder)
            .frame(height: 0.5)
    }

    private var discordLink: some View {
        Group {
            if let url = URL(string: "https://discord.gg/bypass7proxys") {
                Link(destination: url) {
                    Label("Discord BYPASS7 PROXY", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            AppTheme.accent.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .strokeBorder(AppTheme.accentBorder, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
            }
        }
    }
}
