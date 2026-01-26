# Flutter 개발 가이드 (Next.js 개발자를 위한)

> 이 문서는 Next.js/React 경험이 있는 개발자가 MINGRR Flutter 프로젝트를 이해하기 위한 가이드입니다.

---

## 목차

1. [Next.js vs Flutter 개념 비교](#1-nextjs-vs-flutter-개념-비교)
2. [프로젝트 시작점 (Entry Point)](#2-프로젝트-시작점-entry-point)
3. [프로젝트 구조](#3-프로젝트-구조)
4. [화면(UI) 구성 방식](#4-화면ui-구성-방식)
5. [상태 관리 (Riverpod)](#5-상태-관리-riverpod)
6. [라우팅 (화면 이동)](#6-라우팅-화면-이동)
7. [API 연동 (Firebase)](#7-api-연동-firebase)
8. [데이터 모델](#8-데이터-모델)
9. [주요 파일 설명](#9-주요-파일-설명)
10. [자주 사용하는 패턴](#10-자주-사용하는-패턴)

---

## 1. Next.js vs Flutter 개념 비교

| 개념 | Next.js / React | Flutter | MINGRR 예시 |
|------|-----------------|---------|-------------|
| **컴포넌트** | `function Component()` | `class Widget` / `StatelessWidget` | `DatingCard`, `TopNavigation` |
| **상태 관리** | `useState`, `useContext`, Redux | Riverpod (`Provider`, `StateNotifier`) | `authStateProvider`, `datingPetsProvider` |
| **라우팅** | `pages/`, `app/`, Next Router | `go_router` | `app.dart`의 `GoRouter` |
| **스타일링** | CSS, Tailwind, styled-components | `ThemeData`, 인라인 스타일 | `app_theme.dart`, `feature_colors.dart` |
| **API 호출** | `fetch`, Axios, SWR | `http`, Firebase SDK | `firestore_service.dart` |
| **빌드 결과물** | HTML/JS/CSS (웹) | 네이티브 바이너리 (iOS/Android) | APK, IPA |
| **패키지 관리** | `package.json` (npm) | `pubspec.yaml` (pub) | `pubspec.yaml` |

### 핵심 차이점

```
Next.js: JSX로 HTML 구조 작성 → 브라우저가 렌더링
Flutter: Widget 트리 작성 → Flutter 엔진이 직접 렌더링 (네이티브)
```

---

## 2. 프로젝트 시작점 (Entry Point)

### Next.js의 경우
```javascript
// pages/_app.js 또는 app/layout.js
export default function App({ Component, pageProps }) {
  return <Component {...pageProps} />
}
```

### Flutter (MINGRR)의 경우

**시작 파일**: `lib/main.dart`

```dart
// lib/main.dart
void main() async {
  // 1. Flutter 바인딩 초기화 (필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase 초기화 (백엔드 연결)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. API 키 로드 (Remote Config)
  await ApiConfig.initialize();

  // 4. 카카오맵 SDK 초기화
  if (ApiConfig.hasKakaoMapKey) {
    await KakaoMapSdk.instance.initialize(ApiConfig.kakaoMapKey);
  }

  // 5. 앱 실행
  runApp(
    const ProviderScope(  // Riverpod 상태 관리 범위
      child: MingrrApp(),  // 앱 메인 위젯
    ),
  );
}
```

**실행 흐름**:
```
main.dart (초기화)
    ↓
app.dart (MingrrApp - 테마, 라우팅 설정)
    ↓
GoRouter (로그인 체크 → 적절한 화면으로 이동)
    ↓
각 Screen (home_screen.dart, dating_screen.dart 등)
```

---

## 3. 프로젝트 구조

### Next.js 구조 (참고)
```
src/
├── pages/          # 라우팅 (파일 기반)
├── components/     # 재사용 컴포넌트
├── hooks/          # 커스텀 훅
├── services/       # API 호출
├── styles/         # CSS
└── utils/          # 유틸리티
```

### MINGRR Flutter 구조

```
lib/
├── main.dart                 # 🚀 앱 시작점 (Next.js의 _app.js)
├── app.dart                  # 📱 앱 설정 (테마, 라우팅)
├── firebase_options.dart     # 🔥 Firebase 설정 (자동 생성)
│
├── core/                     # 🔧 공통 모듈 (전역에서 사용)
│   ├── config/               # 설정 (API 키 등)
│   ├── constants/            # 상수 (문자열, 크기, 색상)
│   ├── providers/            # 전역 Provider (상태 관리)
│   ├── services/             # 비즈니스 로직 + API 호출
│   ├── theme/                # 테마 (색상, 텍스트 스타일)
│   ├── utils/                # 유틸리티 함수
│   └── widgets/              # 공통 위젯 (버튼, 카드, 다이얼로그)
│
├── features/                 # 📦 기능별 모듈 (도메인 분리)
│   ├── auth/                 # 인증 (로그인/회원가입)
│   ├── dating/               # 데이팅 기능
│   ├── walk/                 # 산책 기능
│   ├── marketplace/          # 중고거래
│   ├── health/               # 건강수첩
│   ├── social/               # 소모임/커뮤니티
│   ├── chat/                 # 채팅
│   ├── profile/              # 프로필
│   └── ...
│
└── models/                   # 📊 데이터 모델 (TypeScript interface 같은 역할)
    ├── user_model.dart
    ├── pet_model.dart
    └── ...
```

### Feature 폴더 내부 구조

```
features/dating/
├── data/                     # 데이터 레이어 (Repository)
│   └── dating_repository.dart
│
└── presentation/             # UI 레이어
    ├── providers/            # 상태 관리 (React의 hooks + context)
    │   └── dating_provider.dart
    │
    └── screens/              # 화면 (Next.js의 pages)
        ├── dating_screen.dart
        └── pet_detail_screen.dart
```

---

## 4. 화면(UI) 구성 방식

### Next.js/React의 경우
```jsx
function DatingCard({ pet }) {
  const [liked, setLiked] = useState(false);
  
  return (
    <div className="card">
      <img src={pet.imageUrl} alt={pet.name} />
      <h2>{pet.name}</h2>
      <button onClick={() => setLiked(!liked)}>
        {liked ? '❤️' : '🤍'}
      </button>
    </div>
  );
}
```

### Flutter의 경우

```dart
// lib/core/widgets/cards/dating_card.dart

// StatelessWidget: 상태가 없는 위젯 (React의 함수형 컴포넌트 + props만)
class DatingCard extends StatelessWidget {
  final PetModel pet;  // props와 동일
  final VoidCallback? onTap;
  
  const DatingCard({
    super.key,
    required this.pet,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    // JSX 대신 Widget 트리 반환
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // <img> 대신 Image 위젯
            Image.network(pet.profileImageUrl ?? ''),
            
            // <h2> 대신 Text 위젯
            Text(
              pet.name,
              style: AppTextStyles.heading2,
            ),
          ],
        ),
      ),
    );
  }
}
```

### StatefulWidget (상태가 있는 위젯)

```dart
// React의 useState를 사용하는 컴포넌트와 유사
class LikeButton extends StatefulWidget {
  const LikeButton({super.key});
  
  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _liked = false;  // useState(false)와 동일
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
      onPressed: () {
        setState(() {  // setLiked(!liked)와 동일
          _liked = !_liked;
        });
      },
    );
  }
}
```

### ConsumerWidget (Riverpod 상태 사용)

```dart
// React의 useContext + Provider 패턴과 유사
class DatingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch = useContext처럼 Provider의 값을 구독
    final petsAsync = ref.watch(datingPetsProvider);
    
    // AsyncValue 패턴 (로딩/에러/데이터 처리)
    return petsAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('에러: $err'),
      data: (pets) => ListView.builder(
        itemCount: pets.length,
        itemBuilder: (context, index) => DatingCard(pet: pets[index].pet),
      ),
    );
  }
}
```

---

## 5. 상태 관리 (Riverpod)

### Next.js의 상태 관리
```javascript
// React Context + useState
const AuthContext = createContext();

function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  return (
    <AuthContext.Provider value={{ user, setUser }}>
      {children}
    </AuthContext.Provider>
  );
}

// 사용
function Profile() {
  const { user } = useContext(AuthContext);
  return <div>{user?.name}</div>;
}
```

### Flutter Riverpod

**Provider 정의** (`lib/features/auth/presentation/providers/auth_provider.dart`):

```dart
// 1. StreamProvider - 실시간 데이터 구독 (Firebase Auth 상태)
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;  // Firebase Auth 스트림
});

// 2. FutureProvider - 비동기 데이터 한 번 가져오기
final datingPetsProvider = FutureProvider<List<PetWithDistance>>((ref) async {
  final petRepository = ref.watch(petRepositoryProvider);
  return await petRepository.getAllPets();
});

// 3. StateProvider - 단순 상태 (useState와 유사)
final selectedTabProvider = StateProvider<int>((ref) => 0);

// 4. StateNotifierProvider - 복잡한 상태 + 액션 (Redux reducer와 유사)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
```

**Provider 사용**:

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 값 읽기 (구독) - 값이 변경되면 자동 리빌드
    final user = ref.watch(authStateProvider);
    
    // 값 읽기 (1회) - 리빌드 안 함
    final currentTab = ref.read(selectedTabProvider);
    
    // 값 변경
    ref.read(selectedTabProvider.notifier).state = 1;
    
    // 액션 호출
    ref.read(authNotifierProvider.notifier).signOut();
    
    return ...;
  }
}
```

### Provider 종류 비교

| Riverpod Provider | React 대응 | 용도 |
|-------------------|-----------|------|
| `Provider` | `useMemo` | 계산된 값, 의존성 주입 |
| `StateProvider` | `useState` | 단순 상태 |
| `FutureProvider` | `useEffect` + `useState` | 비동기 데이터 1회 |
| `StreamProvider` | `useEffect` + 구독 | 실시간 데이터 |
| `StateNotifierProvider` | `useReducer` | 복잡한 상태 + 액션 |

---

## 6. 라우팅 (화면 이동)

### Next.js의 라우팅
```javascript
// 파일 기반 라우팅
pages/
├── index.js        → /
├── login.js        → /login
├── dating/
│   └── [id].js     → /dating/:id

// 이동
import { useRouter } from 'next/router';
const router = useRouter();
router.push('/dating/123');
```

### Flutter (go_router)

**라우터 정의** (`lib/app.dart`):

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    
    // 로그인 체크 (Next.js의 middleware와 유사)
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = user != null;
      final isLoginRoute = state.uri.path == '/login';
      
      // 로그인 안 됐으면 로그인 페이지로
      if (!isLoggedIn && !isLoginRoute) {
        return '/login';
      }
      return null;  // 리다이렉트 안 함
    },
    
    // 라우트 정의
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dating/:petId',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetDetailScreen(petId: petId);
        },
      ),
      
      // 하단 탭 네비게이션 (ShellRoute)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => HomeScreen()),
          GoRoute(path: '/dating', builder: (_, __) => DatingScreen()),
          GoRoute(path: '/walk', builder: (_, __) => WalkScreen()),
          // ...
        ],
      ),
    ],
  );
});
```

**화면 이동**:

```dart
// 방법 1: context.go (replace)
context.go('/dating');

// 방법 2: context.push (stack에 추가)
context.push('/dating/pet123');

// 방법 3: context.pop (뒤로가기)
context.pop();

// 파라미터 전달
context.push('/dating/pet123?tab=photos');
// 또는
context.pushNamed('petDetail', pathParameters: {'petId': 'pet123'});
```

---

## 7. API 연동 (Firebase)

### Next.js의 API 호출
```javascript
// services/api.js
export async function getPets() {
  const res = await fetch('/api/pets');
  return res.json();
}

// 컴포넌트에서 사용
const { data, error } = useSWR('/api/pets', fetcher);
```

### Flutter Firebase 연동

**서비스 레이어** (`lib/core/services/firestore_service.dart`):

```dart
class FirestoreService {
  final FirebaseService _firebase = FirebaseService();
  
  // CREATE - 데이터 생성
  Future<void> createPet(PetModel pet) async {
    await _firebase.petsCollection.doc(pet.id).set(pet.toFirestore());
  }
  
  // READ - 단일 데이터 조회
  Future<PetModel?> getPet(String petId) async {
    final doc = await _firebase.petsCollection.doc(petId).get();
    if (!doc.exists) return null;
    return PetModel.fromFirestore(doc.data()!, id: doc.id);
  }
  
  // READ - 목록 조회 (쿼리)
  Future<List<PetModel>> getPetsByOwner(String ownerId) async {
    final snapshot = await _firebase.petsCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => PetModel.fromFirestore(doc.data(), id: doc.id))
        .toList();
  }
  
  // READ - 실시간 구독 (Stream)
  Stream<List<PetModel>> watchPetsByOwner(String ownerId) {
    return _firebase.petsCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromFirestore(doc.data(), id: doc.id))
            .toList());
  }
  
  // UPDATE - 데이터 수정
  Future<void> updatePet(PetModel pet) async {
    await _firebase.petsCollection.doc(pet.id).update(pet.toFirestore());
  }
  
  // DELETE - 데이터 삭제
  Future<void> deletePet(String petId) async {
    await _firebase.petsCollection.doc(petId).delete();
  }
}
```

**Provider에서 서비스 사용** (`lib/features/pet/presentation/providers/pet_provider.dart`):

```dart
// 실시간 데이터 구독
final userPetsProvider = StreamProvider.autoDispose<List<PetModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final userId = authState.valueOrNull?.uid;
  
  if (userId == null) return Stream.value([]);
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchPetsByOwner(userId);
});

// 화면에서 사용
class PetListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);
    
    return petsAsync.when(
      loading: () => LoadingWidget(),
      error: (e, _) => ErrorWidget(message: e.toString()),
      data: (pets) => ListView(
        children: pets.map((pet) => PetCard(pet: pet)).toList(),
      ),
    );
  }
}
```

### Firebase 컬렉션 구조

```
Firestore Database
├── users/           # 사용자
│   └── {userId}/
│       ├── nickname
│       ├── email
│       └── ...
│
├── pets/            # 반려동물
│   └── {petId}/
│       ├── ownerId
│       ├── name
│       └── ...
│
├── chats/           # 채팅방
│   └── {chatId}/
│       └── messages/  # 서브컬렉션
│
└── ...
```

---

## 8. 데이터 모델

### TypeScript의 경우
```typescript
interface Pet {
  id: string;
  ownerId: string;
  name: string;
  breed?: string;
  gender: 'male' | 'female';
  birthDate?: Date;
}
```

### Dart 모델 (`lib/models/pet_model.dart`)

```dart
class PetModel extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String? breed;
  final PetGender gender;
  final DateTime? birthDate;
  
  const PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.breed,
    required this.gender,
    this.birthDate,
  });
  
  // Firestore → Model (JSON 파싱과 유사)
  factory PetModel.fromFirestore(Map<String, dynamic> data, {required String id}) {
    return PetModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      breed: data['breed'],
      gender: PetGender.values.firstWhere(
        (e) => e.name == data['gender'],
        orElse: () => PetGender.unknown,
      ),
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
    );
  }
  
  // Model → Firestore (JSON 직렬화와 유사)
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'gender': gender.name,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    };
  }
  
  // 불변 객체 복사 (React의 spread 연산자와 유사)
  PetModel copyWith({
    String? name,
    String? breed,
    // ...
  }) {
    return PetModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      gender: gender,
      birthDate: birthDate,
    );
  }
  
  // Equatable: 객체 비교용 (React의 memo 최적화와 유사)
  @override
  List<Object?> get props => [id, ownerId, name, breed, gender, birthDate];
}
```

---

## 9. 주요 파일 설명

### 앱 설정 파일

| 파일 | 역할 | Next.js 대응 |
|------|------|-------------|
| `pubspec.yaml` | 패키지 의존성 | `package.json` |
| `lib/main.dart` | 앱 시작점 | `pages/_app.js` |
| `lib/app.dart` | 라우팅, 테마 설정 | `app/layout.js` + 라우터 |
| `lib/firebase_options.dart` | Firebase 설정 | `.env` + Firebase config |

### 핵심 서비스 파일

| 파일 | 역할 |
|------|------|
| `core/services/firestore_service.dart` | Firestore CRUD 작업 |
| `core/services/auth_service.dart` | 인증 관련 |
| `core/services/storage_service.dart` | 파일 업로드 (이미지 등) |
| `core/services/location_service.dart` | 위치 관련 |
| `core/services/chat_service.dart` | 채팅 기능 |

### 상태 관리 파일

| 파일 | 역할 |
|------|------|
| `features/auth/presentation/providers/auth_provider.dart` | 로그인 상태 |
| `features/dating/presentation/providers/dating_provider.dart` | 데이팅 데이터 |
| `core/providers/location_provider.dart` | 위치 상태 |
| `core/providers/theme_provider.dart` | 테마 (다크모드 등) |

### 공통 위젯

| 폴더 | 내용 |
|------|------|
| `core/widgets/buttons/` | 버튼 컴포넌트 |
| `core/widgets/cards/` | 카드 컴포넌트 |
| `core/widgets/dialogs/` | 다이얼로그/모달 |
| `core/widgets/navigation/` | 네비게이션 바 |
| `core/widgets/loading/` | 로딩 인디케이터 |

---

## 10. 자주 사용하는 패턴

### 1. 비동기 데이터 로딩 (AsyncValue)

```dart
// Next.js의 SWR/React Query와 유사
final dataAsync = ref.watch(someProvider);

return dataAsync.when(
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('에러: $err'),
  data: (data) => MyWidget(data: data),
);
```

### 2. 조건부 렌더링

```dart
// React: {condition && <Component />}
// Flutter:
if (condition) MyWidget(),

// React: {condition ? <A /> : <B />}
// Flutter:
condition ? WidgetA() : WidgetB(),
```

### 3. 리스트 렌더링

```dart
// React: items.map(item => <Item key={item.id} />)
// Flutter:
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
)

// 또는 Column 안에서
Column(
  children: items.map((item) => ItemWidget(item: item)).toList(),
)
```

### 4. 폼 입력

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _controller = TextEditingController();  // useState('')와 유사
  
  @override
  void dispose() {
    _controller.dispose();  // 메모리 정리 (useEffect cleanup)
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        // 입력값 변경 시
      },
      onSubmitted: (value) {
        // 엔터 키 입력 시
      },
    );
  }
}
```

### 5. 생명주기 (Lifecycle)

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // useEffect(() => { ... }, [])와 유사 - 마운트 시 1회 실행
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 의존성 변경 시 실행
  }
  
  @override
  void dispose() {
    // useEffect의 cleanup 함수와 유사 - 언마운트 시 실행
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### 6. 네비게이션 + 데이터 전달

```dart
// 화면 이동 + 파라미터 전달
context.push('/pet/${pet.id}');

// 받는 쪽
GoRoute(
  path: '/pet/:petId',
  builder: (context, state) {
    final petId = state.pathParameters['petId']!;
    return PetDetailScreen(petId: petId);
  },
)

// 결과 받기 (모달에서 선택 등)
final result = await context.push<String>('/select-pet');
if (result != null) {
  // 선택된 값 처리
}
```

---

## 빠른 참조

### 자주 쓰는 위젯

| 용도 | Flutter 위젯 | HTML/React 대응 |
|------|-------------|-----------------|
| 텍스트 | `Text()` | `<p>`, `<span>` |
| 버튼 | `ElevatedButton()`, `TextButton()` | `<button>` |
| 이미지 | `Image.network()`, `Image.asset()` | `<img>` |
| 입력 | `TextField()` | `<input>` |
| 컨테이너 | `Container()` | `<div>` |
| 세로 배치 | `Column()` | `flex-direction: column` |
| 가로 배치 | `Row()` | `flex-direction: row` |
| 스크롤 | `ListView()`, `SingleChildScrollView()` | `overflow: scroll` |
| 여백 | `Padding()`, `SizedBox()` | `padding`, `margin` |
| 클릭 | `GestureDetector()`, `InkWell()` | `onClick` |

### 자주 쓰는 명령어

```bash
# 패키지 설치
flutter pub get

# 앱 실행
flutter run

# 빌드
flutter build apk --release
flutter build ios --release

# 코드 분석
flutter analyze

# 테스트
flutter test
```

---

## 추가 학습 자료

1. **Flutter 공식 문서**: https://docs.flutter.dev
2. **Riverpod 공식 문서**: https://riverpod.dev
3. **go_router 문서**: https://pub.dev/packages/go_router
4. **Firebase Flutter**: https://firebase.google.com/docs/flutter

---

> 💡 **팁**: React/Next.js 경험이 있다면 Flutter의 위젯 = 컴포넌트, Provider = Context + hooks로 생각하면 이해가 빠릅니다. 가장 큰 차이점은 Flutter는 CSS가 없고 모든 스타일이 위젯의 속성으로 들어간다는 점입니다.
