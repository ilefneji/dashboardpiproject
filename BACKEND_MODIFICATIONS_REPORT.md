# 📋 RAPPORT DÉTAILLÉ DES MODIFICATIONS BACKEND REQUISES
**Date:** 3 Avril 2026  
**Projet:** Construction Dashboard - Gestion des Organisations  
**Version:** 1.1 (Mise à jour: Pagination et Messages)

---

## 1. 🎯 RÉSUMÉ EXÉCUTIF

Le frontend a été amélioré pour permettre:
- ✅ Affichage détaillé des organisations (avec type d'organisme)
- ✅ Édition des organisations existantes
- ✅ Création d'organisations avec type
- ✅ Suppression d'organisations (existant déjà)
- ✅ **Pagination sur la liste des organisations**
- ✅ **Messages de confirmation pour chaque action**

Le backend doit supporter ces nouvelles fonctionnalités en exposant les endpoints correspondants et en gérant le champ `organismeType`.

---

## 2. 📊 MODIFICATIONS DE DONNÉES REQUISES

### 2.1 Entité Organization (Modèle de données)

**Champs existants:** ✅
- `id` (Integer) - Identifiant unique
- `name` (String) - Nom de l'organisation
- `createdAt` (DateTime) - Date de création

**Nouveaux champs à ajouter:** ⚠️
- `organismeType` (String, nullable) - Type d'organisme
  - Valeurs possibles:
    - `Bureau d'Étude`
    - `Bureau de Contrôle`
    - `Entreprise d'Exécution`
    - `Autre`
- `description` (String, nullable) - Description de l'organisation

**Structure JSON retournée:**
```json
{
  "id": 1,
  "name": "Construction Corp SARL",
  "organismeType": "Bureau d'Étude",
  "description": "Bureau d'étude spécialisé en construction",
  "createdAt": "2026-03-15T10:30:00Z"
}
```

---

## 3. 🔌 ENDPOINTS API REQUIS

### 3.1 GET /organizations (AVEC PAGINATION)
**Objectif:** Récupérer la liste de toutes les organisations avec pagination  
**Méthode:** GET  
**Authentication:** Bearer Token (JWT)  
**Query Parameters:**
- `page` (Integer, default: 1) - Numéro de la page
- `limit` (Integer, default: 10) - Nombre d'éléments par page
- `search` (String, optional) - Recherche par nom

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Exemples d'appels:**
```
GET /organizations?page=1&limit=10
GET /organizations?page=2&limit=15
GET /organizations?page=1&limit=10&search=Construction
```

**Response (200 - Succès):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Construction Corp",
      "organismeType": "Bureau d'Étude",
      "createdAt": "2026-03-15T10:30:00Z"
    },
    {
      "id": 2,
      "name": "Control Engineering",
      "organismeType": "Bureau de Contrôle",
      "createdAt": "2026-03-16T14:20:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "totalPages": 3,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}
```

**Response (401 - Non authentifié):**
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

---

### 3.2 GET /organizations/:id
**Objectif:** Récupérer les détails d'une organisation spécifique  
**Méthode:** GET  
**Paramètres:** 
- `id` (URL parameter) - Identifiant de l'organisation

**Response (200 - Succès):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Construction Corp",
    "organismeType": "Bureau d'Étude",
    "createdAt": "2026-03-15T10:30:00Z"
  }
}
```

**Response (404 - Non trouvé):**
```json
{
  "success": false,
  "message": "Organization not found"
}
```

---

### 3.3 POST /organizations (AVEC MESSAGE DE CONFIRMATION)
**Objectif:** Créer une nouvelle organisation  
**Méthode:** POST  
**Authentication:** Bearer Token (JWT)  

**Request Body:**
```json
{
  "name": "New Construction Company",
  "organismeType": "Entreprise d'Exécution",
  "description": "Entreprise de construction générale"
}
```

**Response (200/201 - Succès):**
```json
{
  "success": true,
  "message": "Organization created successfully",
  "data": {
    "id": 3,
    "name": "New Construction Company",
    "organismeType": "Entreprise d'Exécution",
    "description": "Entreprise de construction générale",
    "createdAt": "2026-04-03T12:00:00Z"
  }
}
```

**Response (400 - Erreur validation):**
```json
{
  "success": false,
  "message": "Name is required"
}
```

---

### 3.4 PUT /organizations/:id (AVEC MESSAGE DE CONFIRMATION) ⚠️ NOUVEAU ENDPOINT
**Objectif:** Mettre à jour une organisation existante  
**Méthode:** PUT  
**Authentication:** Bearer Token (JWT)  
**Paramètres:**
- `id` (URL parameter) - Identifiant de l'organisation

**Request Body:**
```json
{
  "name": "Updated Organization Name",
  "organismeType": "Bureau de Contrôle",
  "description": "Description mise à jour"
}
```

**Response (200 - Succès):**
```json
{
  "success": true,
  "message": "Organization updated successfully",
  "data": {
    "id": 1,
    "name": "Updated Organization Name",
    "organismeType": "Bureau de Contrôle",
    "description": "Description mise à jour",
    "createdAt": "2026-03-15T10:30:00Z"
  }
}
```

**Response (404 - Non trouvé):**
```json
{
  "success": false,
  "message": "Organization not found"
}
```

**Response (400 - Erreur validation):**
```json
{
  "success": false,
  "message": "Invalid input"
}
```

---

### 3.5 DELETE /organizations/:id (AVEC MESSAGE DE CONFIRMATION)
**Objectif:** Supprimer une organisation (existant déjà)  
**Méthode:** DELETE  
**Authentication:** Bearer Token (JWT)  
**Paramètres:**
- `id` (URL parameter) - Identifiant de l'organisation

**Response (200 - Succès):**
```json
{
  "success": true,
  "message": "Organization deleted successfully"
}
```

**Response (404 - Non trouvé):**
```json
{
  "success": false,
  "message": "Organization not found"
}
```

---

## 4. 📝 EXEMPLE D'IMPLÉMENTATION (NestJS/TypeORM)

### 4.1 Entity - Organization.entity.ts
```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('organizations')
export class Organization {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ 
    type: 'varchar', 
    length: 100,
    nullable: true,
    enum: ['Bureau d\'Étude', 'Bureau de Contrôle', 'Entreprise d\'Exécution', 'Autre']
  })
  organismeType?: string;

  @Column({ 
    type: 'text',
    nullable: true
  })
  description?: string;

  @CreateDateColumn()
  createdAt: Date;
}
```

### 4.2 DTO - Create/Update Organization
```typescript
import { IsString, IsOptional, IsEnum } from 'class-validator';

export class CreateOrganizationDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsEnum(['Bureau d\'Étude', 'Bureau de Contrôle', 'Entreprise d\'Exécution', 'Autre'])
  organismeType?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateOrganizationDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(['Bureau d\'Étude', 'Bureau de Contrôle', 'Entreprise d\'Exécution', 'Autre'])
  organismeType?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class PaginationQueryDto {
  @IsOptional()
  @IsNumber()
  page?: number = 1;

  @IsOptional()
  @IsNumber()
  limit?: number = 10;

  @IsOptional()
  @IsString()
  search?: string;
}
```

### 4.3 Controller - Organizations.controller.ts
```typescript
import { Controller, Get, Post, Put, Delete, Param, Body, UseGuards, Query } from '@nestjs/common';
import { OrganizationsService } from './organizations.service';
import { CreateOrganizationDto, UpdateOrganizationDto, PaginationQueryDto } from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('organizations')
@UseGuards(JwtAuthGuard)
export class OrganizationsController {
  constructor(private organizationsService: OrganizationsService) {}

  @Get()
  findAll(@Query() paginationQuery: PaginationQueryDto) {
    return this.organizationsService.findAll(paginationQuery);
  }

  @Get(':id')
  findOne(@Param('id') id: number) {
    return this.organizationsService.findOne(id);
  }

  @Post()
  create(@Body() createOrgDto: CreateOrganizationDto) {
    return this.organizationsService.create(createOrgDto);
  }

  @Put(':id')
  update(
    @Param('id') id: number,
    @Body() updateOrgDto: UpdateOrganizationDto,
  ) {
    return this.organizationsService.update(id, updateOrgDto);
  }

  @Delete(':id')
  remove(@Param('id') id: number) {
    return this.organizationsService.remove(id);
  }
}
```

### 4.4 Service - Organizations.service.ts (AVEC PAGINATION ET MESSAGES)
```typescript
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { Organization } from './entities/organization.entity';
import { CreateOrganizationDto, UpdateOrganizationDto, PaginationQueryDto } from './dto';

@Injectable()
export class OrganizationsService {
  constructor(
    @InjectRepository(Organization)
    private organizationsRepository: Repository<Organization>,
  ) {}

  async findAll(paginationQuery: PaginationQueryDto) {
    const page = Math.max(1, paginationQuery.page || 1);
    const limit = Math.max(1, paginationQuery.limit || 10);
    const skip = (page - 1) * limit;

    const where = paginationQuery.search
      ? { name: Like(`%${paginationQuery.search}%`) }
      : {};

    const [organizations, total] = await this.organizationsRepository.findAndCount({
      where,
      order: { createdAt: 'DESC' },
      skip,
      take: limit,
    });

    const totalPages = Math.ceil(total / limit);

    return {
      success: true,
      data: organizations,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  async findOne(id: number) {
    const organization = await this.organizationsRepository.findOne({
      where: { id },
    });
    if (!organization) {
      throw new NotFoundException('Organization not found');
    }
    return { success: true, data: organization };
  }

  async create(createOrgDto: CreateOrganizationDto) {
    if (!createOrgDto.name || createOrgDto.name.trim().length === 0) {
      throw new BadRequestException('Name is required');
    }

    const organization = this.organizationsRepository.create(createOrgDto);
    const saved = await this.organizationsRepository.save(organization);
    
    return {
      success: true,
      message: 'Organization created successfully',
      data: saved,
    };
  }

  async update(id: number, updateOrgDto: UpdateOrganizationDto) {
    const organization = await this.organizationsRepository.findOne({
      where: { id },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    // Mettre à jour les champs fournis
    Object.assign(organization, updateOrgDto);
    const saved = await this.organizationsRepository.save(organization);
    
    return {
      success: true,
      message: 'Organization updated successfully',
      data: saved,
    };
  }

  async remove(id: number) {
    const organization = await this.organizationsRepository.findOne({
      where: { id },
    });

    if (!organization) {
      throw new NotFoundException('Organization not found');
    }

    await this.organizationsRepository.remove(organization);
    
    return {
      success: true,
      message: 'Organization deleted successfully',
    };
  }
}
```

---

## 5. 📋 CHECKLIST MIGRATION BASE DE DONNÉES

### Pour PostgreSQL:
```sql
-- Ajouter la colonne organismeType si elle n'existe pas
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS organismeType VARCHAR(100) NULL;

-- Ajouter la colonne description si elle n'existe pas
ALTER TABLE organizations 
ADD COLUMN IF NOT EXISTS description TEXT NULL;

-- Créer une contrainte ENUM (optionnel)
ALTER TABLE organizations 
ADD CONSTRAINT check_organisme_type 
CHECK (organismeType IN ('Bureau d''Étude', 'Bureau de Contrôle', 'Entreprise d''Exécution', 'Autre') OR organismeType IS NULL);

-- Créer un index sur le nom pour les recherches
CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);
```

### Pour MongoDB:
```javascript
// Aucune migration nécessaire - schéma flexible
// Les champs organismeType et description seront créés automatiquement
// Créer un index pour les recherches
db.organizations.createIndex({ name: 1 });
```

---

## 6. 🧪 TESTS RECOMMANDÉS

### Test 1: Créer une organisation avec type et description
```bash
curl -X POST http://localhost:5000/organizations \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Company",
    "organismeType": "Bureau d'\''Étude",
    "description": "Bureau d'\''étude spécialisé en construction"
  }'
```
✅ Doit retourner: `"message": "Organization created successfully"` avec description

### Test 2: Récupérer toutes les organisations (page 1)
```bash
curl -X GET "http://localhost:5000/organizations?page=1&limit=10" \
  -H "Authorization: Bearer <token>"
```
✅ Doit retourner: pagination avec `page`, `limit`, `total`, `totalPages`, `hasNextPage`, `hasPreviousPage`

### Test 3: Récupérer les organisations avec recherche
```bash
curl -X GET "http://localhost:5000/organizations?page=1&limit=10&search=Construction" \
  -H "Authorization: Bearer <token>"
```
✅ Doit retourner: seulement les organisations contenant "Construction"

### Test 4: Aller à la page 2
```bash
curl -X GET "http://localhost:5000/organizations?page=2&limit=10" \
  -H "Authorization: Bearer <token>"
```
✅ Doit retourner: `"hasNextPage"` et `"hasPreviousPage"` corrects

### Test 5: Mettre à jour une organisation
```bash
curl -X PUT http://localhost:5000/organizations/1 \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Company",
    "organismeType": "Bureau de Contrôle",
    "description": "Description mise à jour"
  }'
```
✅ Doit retourner: `"message": "Organization updated successfully"` avec description mise à jour

### Test 6: Supprimer une organisation
```bash
curl -X DELETE http://localhost:5000/organizations/1 \
  -H "Authorization: Bearer <token>"
```
✅ Doit retourner: `"message": "Organization deleted successfully"`

---

## 7. ⚠️ NOTES IMPORTANTES

### Pagination
1. **Paramètres par défaut:** page=1, limit=10
2. **Validation:** page et limit doivent être ≥ 1
3. **Calcul:** totalPages = ceil(total / limit)
4. **Flags:** 
   - `hasNextPage` = true si page < totalPages
   - `hasPreviousPage` = true si page > 1

### Messages de confirmation
1. **Création:** "Organization created successfully"
2. **Modification:** "Organization updated successfully"
3. **Suppression:** "Organization deleted successfully"
4. **Erreurs:** Messages clairs décrivant le problème

### Autres considérations
1. **Authentication:** Tous les endpoints (sauf peut-être GET list/detail) doivent vérifier le JWT
2. **Validation:** 
   - `name` est obligatoire et ne doit pas être vide
   - `organismeType` est optionnel et doit être dans l'enum
3. **Erreurs:** Retourner des codes HTTP appropriés (200, 201, 400, 404, 401)
4. **Base de données:** Ajouter les migrations nécessaires pour le champ `organismeType`
5. **Documentation API:** Mettre à jour la documentation Swagger/OpenAPI
6. **Index BD:** Créer un index sur le champ `name` pour optimiser les recherches

---

## 8. 📞 SUPPORT

Si vous avez des questions:
- ✔️ Vérifiez que tous les endpoints retournent le format JSON spécifié
- ✔️ Testez chaque endpoint avec les exemples curl fournis
- ✔️ Assurez-vous que l'authentification JWT fonctionne correctement
- ✔️ Validez que la pagination fonctionne correctement entre les pages
- ✔️ Confirmez que les messages de confirmation sont retournés pour chaque action

---

**Statut:** ✅ Prêt pour implémentation  
**Priorité:** Haute  
**Estimation:** 2-3 heures de développement  
**Dernière mise à jour:** 3 Avril 2026 - Version 1.1 (Pagination + Messages)
