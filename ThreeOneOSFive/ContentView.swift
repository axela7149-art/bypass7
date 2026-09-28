import SwiftUI
import UIKit

struct LoginView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @FocusState private var isKeyFieldFocused: Bool
    @State private var contentVisible = false

    private let accent = AppTheme.accent

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        accent.opacity(0.22),
                        Color.black.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 28)

                    ZStack {
                        Circle()
                            .fill(AppTheme.accentSoft)
                            .frame(width: 96, height: 96)
                        AppLogo(size: 76)
                    }
                    .accessibilityHidden(true)

                    Text("BYPASS7 PROXY")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(accent)
                        SecureField("Digite sua key", text: $viewModel.enteredKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isKeyFieldFocused)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isKeyFieldFocused ? accent.opacity(0.9) : AppTheme.accentBorder, lineWidth: 1)
                            )
                            .foregroundStyle(.white)
                            .tint(accent)
                            .onSubmit { submit() }
                    }
                    .padding(.horizontal, 8)

                    Button(action: submit) {
                        Group {
                            if viewModel.isLoading {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Validando...")
                                }
                            } else if viewModel.isRevalidating {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Revalidando...")
                                }
                            } else {
                                Text("Entrar")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(viewModel.isLoading || viewModel.isRevalidating)
                    .buttonStyle(AppPressableButtonStyle())
                    .padding(.horizontal, 8)

                    if viewModel.showError {
                        Text(viewModel.errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    if let discordURL = URL(string: "https://discord.gg/bypass7proxys") {
                        Link(destination: discordURL) {
                            Label("Discord BYPASS7 PROXY", systemImage: "bubble.left.and.bubble.right.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(AppTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    AppTheme.accent.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .strokeBorder(AppTheme.accentBorder, lineWidth: 1)
                                }
                        }
                        .accessibilityLabel("Discord BYPASS7 PROXY")
                        .padding(.horizontal, 8)
                    }

                    Spacer(minLength: 28)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
            }
            .scrollDismissesKeyboard(.interactively)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 8)
        }
        .preferredColorScheme(.dark)
        .onTapGesture {
            isKeyFieldFocused = false
        }
        .onAppear {
            withAnimation(.easeOut(duration: AppTheme.motionDuration)) {
                contentVisible = true
            }
        }
    }

    private func submit() {
        guard !viewModel.isLoading else { return }
        Task { await viewModel.login() }
    }
}

/// The five redesigned tabs. Selection is kept local to `ContentView` so the
/// shared `AppSection` / `AppTabNavigationState` navigation layer stays intact.
private enum StudioTab: String, CaseIterable, Identifiable {
    case aims
    case esp
    case chams
    case textures
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aims: return "Aims"
        case .esp: return "Esp"
        case .chams: return "Chams"
        case .textures: return "Texturas"
        case .home: return "Home"
        }
    }

    var symbol: String {
        switch self {
        case .aims: return "scope"
        case .esp: return "eye.fill"
        case .chams: return "paintpalette.fill"
        case .textures: return "square.stack.3d.up.fill"
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
                        AimsTabView()
                    case .esp:
                        EspTabView()
                    case .chams:
                        ChamsTabView()
                    case .textures:
                        TexturasTabView()
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

/// Visual-only "Esp" tab. Clean placeholder body.
private struct EspTabView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                GameStatusPill()

                Text("Em breve colocaremos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 64)
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }
}

/// Visual-only "Texturas" tab. Prepared grid of placeholder cards for future
/// textures, with no logic wired yet.
private struct TexturasTabView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                GameStatusPill()

                VStack(alignment: .leading, spacing: 10) {
                    Text("TEXTURAS")
                        .font(.subheadline.weight(.bold))
                        .kerning(0.6)
                        .foregroundStyle(.primary)

                    AppCard(padding: 14) {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(0..<6, id: \.self) { _ in
                                placeholderCard
                            }
                        }
                    }
                }

                Text("Em breve colocaremos novas texturas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private var placeholderCard: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            AppTheme.surfaceBorder,
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                )
                .overlay(
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.secondary)
                )
                .aspectRatio(1, contentMode: .fit)

            Text("Textura")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Visual-only "Chams" tab. Single-select color hologram picker, no logic wired.
private struct ChamsTabView: View {
    private enum ColorOption: String, CaseIterable, Hashable, Identifiable {
        case amarelo
        case vermelho
        case roxo
        case laranja
        case preto
        case branco

        var id: String { rawValue }

        var title: String {
            switch self {
            case .amarelo: return "AMARELO"
            case .vermelho: return "VERMELHO"
            case .roxo: return "ROXO"
            case .laranja: return "LARANJA"
            case .preto: return "PRETO"
            case .branco: return "BRANCO"
            }
        }

        var subtitle: String {
            switch self {
            case .amarelo: return "Contorno holográfico amarelo nas armas"
            case .vermelho: return "Contorno holográfico vermelho nas armas"
            case .roxo: return "Contorno holográfico roxo nas armas"
            case .laranja: return "Contorno holográfico laranja nas armas"
            case .preto: return "Contorno holográfico preto nas armas"
            case .branco: return "Contorno holográfico branco nas armas"
            }
        }

        var swatch: Color {
            switch self {
            case .amarelo: return Color(red: 1.00, green: 0.84, blue: 0.00)
            case .vermelho: return Color(red: 0.92, green: 0.20, blue: 0.20)
            case .roxo: return Color(red: 0.60, green: 0.30, blue: 0.96)
            case .laranja: return Color(red: 1.00, green: 0.55, blue: 0.10)
            case .preto: return Color(white: 0.12)
            case .branco: return Color(white: 0.98)
            }
        }

        var symbol: String { "circle.fill" }
    }

    @State private var selectedColor: ColorOption?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                GameStatusPill()

                AppCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            AppRowIcon(systemName: "paintpalette.fill", tint: AppTheme.accent, frameSize: 36)
                            Text("HOLOGRAMA ARMAS")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.primary)
                        }

                        Text("Selecione uma cor para aplicar no jogo escolhido. Mantenha apenas uma opção ativa por vez.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("CORES DISPONÍVEIS")
                        .font(.subheadline.weight(.bold))
                        .kerning(0.6)
                        .foregroundStyle(.primary)

                    AppCard(padding: 4) {
                        VStack(spacing: 0) {
                            ForEach(ColorOption.allCases) { option in
                                if option != ColorOption.allCases.first {
                                    Rectangle()
                                        .fill(AppTheme.surfaceBorder)
                                        .frame(height: 0.5)
                                }
                                AppToggleRow(
                                    title: option.title,
                                    subtitle: option.subtitle,
                                    systemImage: option.symbol,
                                    iconTint: option.swatch,
                                    isOn: colorBinding(option)
                                )
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.pageInset)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
    }

    private func colorBinding(_ option: ColorOption) -> Binding<Bool> {
        Binding(
            get: { selectedColor == option },
            set: { isOn in
                withAnimation(.easeInOut(duration: AppTheme.motionDuration)) {
                    selectedColor = isOn ? option : nil
                }
            }
        )
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
    @State private var hsAlto = false
    @State private var hsPescoco = false
    @State private var hsPescocoAntena = false
    @State private var hsAltoPescoco = false

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
                        title: "HS ALTO",
                        subtitle: "Aumenta a altura da cabeça para facilitar a mira",
                        systemImage: "arrow.up.to.line",
                        isOn: $hsAlto
                    )
                    .padding(.horizontal, 12)

                    separator

                    AppToggleRow(
                        title: "HS PESCOÇO",
                        subtitle: "Mira travada na região do pescoço",
                        systemImage: "scope",
                        isOn: $hsPescoco
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
                        title: "HS ALTO + PESCOÇO",
                        subtitle: "Combina HS alto com a trava de pescoço",
                        systemImage: "arrow.up.and.down",
                        isOn: $hsAltoPescoco
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
