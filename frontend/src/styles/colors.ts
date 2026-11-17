// 명지은행 디자인 시스템 색상 토큰 (Figma "00 Design System" 기준)

export type ThemeMode = 'light' | 'dark';

/** 공통 색상 토큰 */
export const colors = {
  light: {
    primary: '#5C6B3A',       // 버튼, 강조
    primaryStrong: '#3F4A26', // 사이드바
    accent: '#C3B091',        // 카키 포인트
    bg: '#F7F6F0',            // 페이지 배경
    surface: '#FFFFFF',       // 카드
    surfaceMuted: '#F2F1E8',  // 표 헤더, 탭 배경
    border: '#E4E1D3',        // 테두리
    text: '#23261C',          // 본문
    textMuted: '#6E7160',     // 보조 텍스트
    success: '#4E7A3A',       // 입금
    danger: '#B5523B',        // 출금, 삭제
    selected: '#EEF1E0',      // 선택된 행
  },
  dark: {
    primary: '#9DAE6B',
    primaryStrong: '#1E2414',
    accent: '#B29E7C',
    bg: '#15170F',
    surface: '#1F2318',
    surfaceMuted: '#282D1F',
    border: '#353A2A',
    text: '#ECEDE4',
    textMuted: '#A3A690',
    success: '#8DBA6E',
    danger: '#E08A72',
    selected: '#2E3522',
  },
} as const satisfies Record<ThemeMode, Record<string, string>>;

/** 컴포넌트 전용 색상 */
export const componentColors = {
  light: {
    onPrimary: '#FFFFFF',      // Primary 버튼 글자
    ghostBorder: '#C9CDB2',    // Ghost 버튼 테두리
    dangerBorder: '#E3C3B9',   // Danger 버튼 테두리
    badgeInBg: '#E9ECD9',      // 입금·신용 배지 배경
    badgeInText: '#4B5730',    // 입금·신용 배지 글자
    badgeOutBg: '#F1E9D8',     // 출금·체크 배지 배경
    badgeOutText: '#7A6235',   // 출금·체크 배지 글자
    inputBg: '#FCFCF8',        // 입력창 배경
    inputBorder: '#DCD9C9',    // 입력창 테두리
    placeholder: '#A5A796',    // placeholder 글자
    navText: '#D5D9C2',        // 사이드바 메뉴 글자
    navActiveBg: '#5C6B3A',    // 사이드바 활성 메뉴 배경
  },
  dark: {
    onPrimary: '#15170F',
    ghostBorder: '#4A5038',
    dangerBorder: '#5A3A30',
    badgeInBg: '#2F3823',
    badgeInText: '#C5D3A0',
    badgeOutBg: '#3A3222',
    badgeOutText: '#D9C29A',
    inputBg: '#1A1D14',
    inputBorder: '#3D4330',
    placeholder: '#6E7160',
    navText: '#A3A690',
    navActiveBg: '#2E3522',
  },
} as const satisfies Record<ThemeMode, Record<string, string>>;

export type ColorToken = keyof typeof colors.light;
export type ComponentColorToken = keyof typeof componentColors.light;

const toKebab = (key: string) => key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`);

/** 모드별 색상을 CSS 변수 객체로 변환. 예: primaryStrong → --color-primary-strong */
export function toCssVars(mode: ThemeMode): Record<string, string> {
  const vars: Record<string, string> = {};
  for (const [key, value] of Object.entries({ ...colors[mode], ...componentColors[mode] })) {
    vars[`--color-${toKebab(key)}`] = value;
  }
  return vars;
}

/** CSS 변수를 대상 요소(기본: <html>)에 적용하고 data-theme 속성을 설정 */
export function applyTheme(mode: ThemeMode, target: HTMLElement = document.documentElement): void {
  for (const [name, value] of Object.entries(toCssVars(mode))) {
    target.style.setProperty(name, value);
  }
  target.dataset.theme = mode;
}
