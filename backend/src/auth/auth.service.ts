import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import axios from 'axios';
import { GoogleLoginDto } from './dto/google-login.dto';
import { KakaoLoginDto } from './dto/kakao-login.dto';

interface GoogleTokenInfoResponse {
  sub: string;
  email?: string;
  name?: string;
}

interface KakaoUserResponse {
  id: number;
  kakao_account?: {
    email?: string;
    profile?: {
      nickname?: string;
    };
  };
}

@Injectable()
export class AuthService {
  constructor(private readonly jwtService: JwtService) {}

  async googleLogin(dto: GoogleLoginDto) {
    const response = await axios.get<GoogleTokenInfoResponse>(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${dto.idToken}`,
    );

    const data: GoogleTokenInfoResponse = response.data;

    if (!data.sub) {
      throw new UnauthorizedException('유효하지 않은 구글 토큰입니다.');
    }

    const user = {
      provider: 'google',
      providerId: data.sub,
      email: data.email ?? null,
      name: data.name ?? data.email ?? 'Google User',
    };

    const accessToken = await this.jwtService.signAsync({
      sub: user.providerId,
      email: user.email,
      provider: user.provider,
    });

    return {
      accessToken,
      isNewUser: true,
      user,
    };
  }

  async kakaoLogin(dto: KakaoLoginDto) {
    const response = await axios.get<KakaoUserResponse>(
      'https://kapi.kakao.com/v2/user/me',
      {
        headers: {
          Authorization: `Bearer ${dto.accessToken}`,
        },
      },
    );

    const data: KakaoUserResponse = response.data;

    if (!data.id) {
      throw new UnauthorizedException('유효하지 않은 카카오 토큰입니다.');
    }

    const user = {
      provider: 'kakao',
      providerId: data.id.toString(),
      email: data.kakao_account?.email ?? null,
      name: data.kakao_account?.profile?.nickname ?? 'Kakao User',
    };

    const accessToken = await this.jwtService.signAsync({
      sub: user.providerId,
      email: user.email,
      provider: user.provider,
    });

    return {
      accessToken,
      isNewUser: true,
      user,
    };
  }
}
