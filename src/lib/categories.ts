export const CATEGORIES = [
  { slug: 'recon', name: 'Recon', icon: 'M21 21l-4.35-4.35M11 19a8 8 0 100-16 8 8 0 000 16z', blurb: 'Passive & active reconnaissance' },
  { slug: 'enumeration', name: 'Enumeration', icon: 'M4 6h16M4 12h16M4 18h16', blurb: 'Service & port enumeration' },
  { slug: 'web', name: 'Web', icon: 'M3.6 9h16.8M3.6 15h16.8M11.5 3a17 17 0 000 18m1-18a17 17 0 010 18M21 12a9 9 0 11-18 0 9 9 0 0118 0z', blurb: 'Web app attacks (SQLi, XSS, SSRF, LFI)' },
  { slug: 'active-directory', name: 'Active Directory', icon: 'M12 4.5l8 4.5v6l-8 4.5L4 15V9l8-4.5z', blurb: 'AD enumeration, Kerberos, ACLs' },
  { slug: 'privesc-linux', name: 'Linux PrivEsc', icon: 'M12 19v-7m0 0l-3 3m3-3l3 3M5 5a2 2 0 012-2h10a2 2 0 012 2v3H5V5z', blurb: 'Linux privilege escalation' },
  { slug: 'privesc-windows', name: 'Windows PrivEsc', icon: 'M3 13h7V3H3v10zm0 8h7v-6H3v6zm11 0h7V11h-7v10zm0-18v6h7V3h-7z', blurb: 'Windows privilege escalation' },
  { slug: 'pivoting', name: 'Pivoting', icon: 'M13 5l7 7-7 7M4 12h16', blurb: 'Tunneling, port forwarding, proxying' },
  { slug: 'reverse-shells', name: 'Reverse Shells', icon: 'M8 9l-4 3 4 3m8-6l4 3-4 3M14 4l-4 16', blurb: 'Shells, upgrades, listeners' },
] as const;

export type CategorySlug = (typeof CATEGORIES)[number]['slug'];

export function categoryBySlug(slug: string) {
  return CATEGORIES.find((c) => c.slug === slug);
}
