import type { Metadata } from 'next'
import './globals.css'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Admin',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko">
      <body>
        <nav className="bg-gray-800 text-white p-4 flex gap-6">
          <span className="font-bold text-lg">관리자 페이지</span>
          <Link href="/users" className="hover:text-gray-300">유저 관리</Link>
          <Link href="/supplements" className="hover:text-gray-300">영양제 관리</Link>
        </nav>
        <main>{children}</main>
      </body>
    </html>
  )
}