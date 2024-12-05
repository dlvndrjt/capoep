import type { Metadata } from "next";
import localFont from "next/font/local";
import "../styles/globals.css";
import { Navbar } from "@/components/navbar"
import { ToastProvider } from "@/components/providers/toast-provider"

const geistSans = localFont({
  src: "./fonts/GeistVF.woff",
  variable: "--font-geist-sans",
  weight: "100 900",
});
const geistMono = localFont({
  src: "./fonts/GeistMonoVF.woff",
  variable: "--font-geist-mono",
  weight: "100 900",
});

export const metadata: Metadata = {
  title: "CAPOE - Community Attested Proof of Education",
  description: "Community-driven educational proof attestation platform",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        <Navbar />
        <main>{children}</main>
        <ToastProvider />
      </body>
    </html>
  )
}
