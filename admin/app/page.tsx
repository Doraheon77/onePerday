'use client'
import { useEffect, useState } from 'react'
import { api } from '../lib/api'
import Link from 'next/link'

export default function DashboardPage() {
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.getDashboard().then(d => {
      setData(d)
      setLoading(false)
    })
  }, [])

  const cards = [
    { label: '전체 유저 수', value: data?.totalUsers ?? '-', icon: '👤', link: '/users', color: '#e8f5e9', border: '#a5d6a7' },
    { label: '전체 영양제 수', value: data?.totalSupplements ?? '-', icon: '💊', link: '/supplements', color: '#e8f5e9', border: '#a5d6a7' },
    { label: '오늘 가입자', value: data?.todayUsers ?? '-', icon: '✨', link: '/users', color: '#f1f8e9', border: '#c5e1a5' },
  ]

  return (
    <div>
      <h1 style={{ fontSize: '22px', fontWeight: 700, color: '#2d8a5e', marginBottom: '0.5rem' }}>
        대시보드
      </h1>
      <p style={{ fontSize: '14px', color: '#888', marginBottom: '2rem' }}>
        {new Date().toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' })}
      </p>

      {loading ? (
        <p style={{ color: '#2d8a5e', textAlign: 'center', padding: '2rem' }}>로딩 중...</p>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '2rem' }}>
          {cards.map(card => (
            <Link key={card.label} href={card.link} style={{ textDecoration: 'none' }}>
              <div style={{
                backgroundColor: card.color, border: `1.5px solid ${card.border}`,
                borderRadius: '14px', padding: '1.5rem', cursor: 'pointer',
                transition: 'transform 0.1s',
              }}>
                <div style={{ fontSize: '32px', marginBottom: '12px' }}>{card.icon}</div>
                <div style={{ fontSize: '13px', color: '#555', marginBottom: '6px', fontWeight: 600 }}>{card.label}</div>
                <div style={{ fontSize: '36px', fontWeight: 700, color: '#2d8a5e' }}>{data ? card.value.toLocaleString() : '-'}</div>
              </div>
            </Link>
          ))}
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
        <Link href="/users" style={{ textDecoration: 'none' }}>
          <div style={{
            backgroundColor: 'white', border: '1.5px solid #c8e6c9',
            borderRadius: '14px', padding: '1.5rem', cursor: 'pointer',
          }}>
            <h2 style={{ fontSize: '16px', fontWeight: 700, color: '#2d8a5e', marginBottom: '8px' }}>👤 유저 관리</h2>
            <p style={{ fontSize: '14px', color: '#888' }}>유저 목록 조회, 검색, 삭제</p>
          </div>
        </Link>
        <Link href="/supplements" style={{ textDecoration: 'none' }}>
          <div style={{
            backgroundColor: 'white', border: '1.5px solid #c8e6c9',
            borderRadius: '14px', padding: '1.5rem', cursor: 'pointer',
          }}>
            <h2 style={{ fontSize: '16px', fontWeight: 700, color: '#2d8a5e', marginBottom: '8px' }}>💊 영양제 관리</h2>
            <p style={{ fontSize: '14px', color: '#888' }}>영양제 목록 조회, 추가, 삭제</p>
          </div>
        </Link>
      </div>
    </div>
  )
}